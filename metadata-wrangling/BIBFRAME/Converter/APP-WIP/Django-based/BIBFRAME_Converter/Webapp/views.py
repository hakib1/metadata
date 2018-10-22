from django.shortcuts import render, redirect
from django.conf import settings
from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from django.views.generic.edit import DeleteView
from Webapp.models import Bib_Document, Marc_Document, Processing, Document, P_progress, Progress_archive
from Webapp.forms import Bib_DocumentForm, Marc_DocumentForm, CheckForm, Del_DocumentForm
import os, signal
from .Code.enrich import marc_process, bib_process
from .Code.Utils import PrintException, clear_processing
from .Code.Classes.BIB_builder import BIB_builder
import threading
import shutil
import time
from datetime import datetime

def index(request):
	docs = Document.objects.all()
	bib_documents = Bib_Document.objects.all()
	bib_form = Bib_DocumentForm(request.POST, request.FILES)
	marc_documents = Marc_Document.objects.all()
	marc_form = Marc_DocumentForm(request.POST, request.FILES)
	processing_documents = Processing.objects.all()
	processing_archive = Progress_archive.objects.all()
	# creating a dummy document to fill the first row of document table (uploaded files)
	# without this the "PROCESS" button would not work
	checksum="thisisadummyobjectonlynumber123456"
	if docs.filter(OID=checksum).exists():
		pass
	else:
		adddummy = Document(description="a dummy object", 
		    		OID=checksum, 
		    		old_id= 123,
		    		name="dumy_object", 
		    		file_type="dummy data",
		    		uploaded_at="2014-09-04 23:34:40.834676",
		    		file_format=".dum")
		adddummy.save()
	for bib in bib_documents:
		checksum = str(bib.id)+str("___")+str(bib.document)+str("___")+str(bib.uploaded_at)
		if docs.filter(OID=checksum).exists():
			pass
		else:
			addbib = Document(description=bib.description, 
	    		OID=checksum, 
	    		old_id= bib.id,
	    		name=bib.document, 
	    		file_type=bib.file_type,
	    		uploaded_at=bib.uploaded_at,
	    		file_format=bib.file_format)
			addbib.save()
	for mrc in marc_documents:
		checksum = str(mrc.id)+str("___")+str(mrc.document)+str("___")+str(mrc.uploaded_at)
		if docs.filter(OID=checksum).exists():
			pass
		else:
			addDoc = Document(description=mrc.description, 
	    		OID=checksum, 
	    		old_id=mrc.id,
	    		name=mrc.document, 
	    		file_type=mrc.file_type,
	    		uploaded_at=mrc.uploaded_at,
	    		file_format=mrc.file_format)
			addDoc.save()
	if len(request.FILES) > 0:
		uploaded_file = request.FILES['document']
		filename = uploaded_file.name
		file_ext = os.path.splitext(filename)[1]
		print (file_ext)
		if file_ext == ".xml":
			bib_folder = 'Webapp/source/BIBFRAME'
			if bib_form.is_valid():
				bib_form.save()
				return redirect('index')
		if file_ext == ".mrc"or file_ext == '.marc':
			marc_folder = 'Webapp/source/MARC'
			if marc_form.is_valid():
				marc_form.save()
				return redirect('index')
	return render(request, 'webapp/index.html', { 'docs': docs, 'processing_documents': processing_documents, 'processing_archive': processing_archive, 'marc_form': marc_form, 'bib_form': bib_form})

def model_form_upload(request):
    return render(request, 'webapp/model_form_upload.html')

def deleteRecord(request, id =None, format=None, old_id=None):
	folder = 'Webapp/source'
	doc = Document.objects.get(id=id)
	doc.delete()
	if format == ".xml":
		object = Bib_Document.objects.get(id=old_id)
		file = str(object.document)
		object.delete()
		file_path = os.path.join(folder, file)
		try:
			if os.path.isfile(file_path):
				os.unlink(file_path)
		except Exception as e:
			print(e)
	if format == ".mrc":
		object = Marc_Document.objects.get(id=old_id)
		file = str(object.document)
		object.delete()
		file_path = os.path.join(folder, file)
		try:
			if os.path.isfile(file_path):
				os.unlink(file_path)
		except Exception as e:
			print(e)
	return redirect('deleted')

def deleted(request):
	return render(request, 'webapp/deleted.html')

def processingQueue(request):
	overload = Processing.objects.all()
	progress = P_progress.objects.all()
	form = CheckForm(request.POST or None)
	file_dict = dict(request.POST.lists())
	merge = False
	apis = ''
	if 'merge' in file_dict.keys():
		merge = True
	if 'file_selected' in file_dict.keys() and 'search-API-selector' in file_dict.keys():
		olcheck = len(overload) + len(file_dict["file_selected"])
		if olcheck > 4:
			return redirect('overload')
		else:
			for n, api in enumerate(file_dict['search-API-selector']):
				if (n+1) < len(file_dict['search-API-selector']):
					apis = apis + '%s_-_' %(api)
				else:
					apis = apis + api
			for item in file_dict['file_selected']:
				try:
					object = Marc_Document.objects.get(document=item)
				except:
					object = Bib_Document.objects.get(document=item)
				add_process = Processing(description=object.description, 
						name=str(object.document), 
						uploaded_at=object.uploaded_at,
						file_format=object.file_format,
						file_type=object.file_type,
						apis=apis,
						files=str(object.document),
						status="started")
				try:
					if object.file_type == 'MARC Data':
						add_process.save()
						t = threading.Thread(target=marc_process, args=[add_process, file_dict['search-API-selector']])
						t.setDaemon(True)
						t.start()
						print (threading.currentThread().getName())
						if not t.isAlive():
							add_process.delete()
					elif object.file_type == 'BIBFRAME Data' and merge == True:
						if not os.path.exists('Webapp/Files/Processing/BIBFRAME'):
							os.makedirs('Webapp/Files/Processing/BIBFRAME')
						oring_file = "Webapp/source/%s" %(str(object.document))
						dest_file = "Webapp/Files/Processing/%s" %(str(object.document))
						shutil.copyfile(oring_file, dest_file)
					elif object.file_type == 'BIBFRAME Data' and merge == False:
						add_process.save()
						t = threading.Thread(target=bib_process, args=[add_process, file_dict['search-API-selector'], merge])
						t.setDaemon(True)
						t.start()
				except:
					return redirect('processing_duplicate')
					break
			if  merge == True:
				BIBFRAME = BIB_builder()
				file = BIBFRAME.merger()
				clear_processing()
				add_process = Processing(description="merged BIBFRAME file", 
						name=str(file[0].replace('Webapp/Files/Processing/', '')), 
						uploaded_at=datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S'),
						file_format='.xml',
						file_type='BIBFRAME Data',
						apis=apis,
						files=file[1],
						status="started")
				add_process.save()
				t = threading.Thread(target=bib_process, args=[add_process, file_dict['search-API-selector'], merge] )
				t.setDaemon(True)
				t.start()
	processing_docs = Processing.objects.all()
	return render(request, 'webapp/processing.html', {'processing_docs': processing_docs, 'P_progress': P_progress})

def progress(request):
	update_marc = [item.as_marc() for item in P_progress.objects.all()]
	update_bib = [item.as_bib() for item in P_progress.objects.all()]
	return JsonResponse({'latest_progress_marc':update_marc, 'latest_progress_bib':update_bib})

def overload(request):
	return render(request, 'webapp/overload.html')

def processing(request, id=None):
	object = Processing.objects.get(id=id)
	return main (object)

def processing_duplicate(request):
	return render(request, 'webapp/processing_duplicate.html')

def stop(request, id =None):
	object = Processing.objects.get(id=id)
	pid = object.id
	files = P_progress.objects.get(pid_id=pid)
	object.delete()
	master_file = files.master_file
	folders ={'Webapp/Files/converted_BIBFRAME', 'Webapp/Files/MARC_XML', 'Webapp/Files/Processing', 'Webapp/Files/results'}
	BIB_folder = 'Webapp/Files/converted_BIBFRAME'
	MARC_folder = 'Webapp/Files/MARC_XML'
	Processing_folder = 'Webapp/Files/Processing'
	results_folder = 'Webapp/Files/results'
	for folder in folders:
		master = "%s/%s" %(folder, master_file)
		if os.path.isdir(master):
			shutil.rmtree(master)
		elif os.path.isfile(master):
			os.unlink(master)
	#pid = os.getpid()
	#os.kill(pid, signal.SIGKILL)
	return render(request, 'webapp/stop.html')

def archive(request):
	archives = Progress_archive.objects.all()
	return render(request, 'webapp/archive.html', {'archives': archives})

def delete_archive(request, id =None):
	object = Progress_archive.objects.get(id=id)
	master_file = object.master_file
	object.delete()
	folders ={'Webapp/Files/converted_BIBFRAME', 'Webapp/Files/MARC_XML', 'Webapp/Files/Processing', 'Webapp/Files/results'}
	BIB_folder = 'Webapp/Files/converted_BIBFRAME'
	MARC_folder = 'Webapp/Files/MARC_XML'
	Processing_folder = 'Webapp/Files/Processing'
	results_folder = 'Webapp/Files/results'
	for folder in folders:
		master = "%s/%s" %(folder, master_file)
		if os.path.isdir(master):
			shutil.rmtree(master)
		elif os.path.isfile(master):
			os.unlink(master)
	return render(request, 'webapp/arc_del.html')

def delete_archive_all(request):
	for object in Progress_archive.objects.all():
		master_file = object.master_file
		object.delete()
		folders ={'Webapp/Files/converted_BIBFRAME', 'Webapp/Files/MARC_XML', 'Webapp/Files/Processing', 'Webapp/Files/results'}
		BIB_folder = 'Webapp/Files/converted_BIBFRAME'
		MARC_folder = 'Webapp/Files/MARC_XML'
		Processing_folder = 'Webapp/Files/Processing'
		results_folder = 'Webapp/Files/results'
		for folder in folders:
			master = "%s/%s" %(folder, master_file)
			if os.path.isdir(master):
				shutil.rmtree(master)
			elif os.path.isfile(master):
				os.unlink(master)
	return render(request, 'webapp/arc_del.html')
