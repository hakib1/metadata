from django.db import models

class Document(models.Model):
    description = models.CharField(max_length=255, blank=True)
    OID = models.CharField(max_length=355, blank=True)
    old_id = models.CharField(max_length=25, blank=True)
    name = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    file_format = models.CharField(max_length=5, default='.xml',)
    file_type = models.CharField(max_length=15,  default='BIBFRAME Data',)

class Marc_Document(models.Model):
    description = models.CharField(max_length=255, blank=True)
    document = models.FileField(upload_to='./MARC')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    file_format = models.CharField(max_length=5,  default='.mrc',)
    file_type = models.CharField(max_length=15,  default='MARC Data',)

class Bib_Document(models.Model):
    description = models.CharField(max_length=255, blank=True)
    document = models.FileField(upload_to='./BIBFRAME')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    file_format = models.CharField(max_length=5, default='.xml',)
    file_type = models.CharField(max_length=15,  default='BIBFRAME Data',)


class Processing(models.Model):
    description = models.CharField(max_length=255, blank=True)
    name = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=False)
    file_format = models.CharField(max_length=5,default='.xml')
    file_type = models.CharField(max_length=155,default='BIBFRAME Data')
    start_time = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=50, default='not started')
    class Meta:
        unique_together = ["name", "uploaded_at", "file_type", "description"]

class P_progress(models.Model):
    pid = models.ForeignKey(Processing, on_delete=models.CASCADE)
    all_names = models.CharField(max_length=25, blank=True)
    all_titles = models.CharField(max_length=25, blank=True)
    p_names = models.CharField(max_length=25, blank=True)
    c_names = models.CharField(max_length=25, blank=True)
    name_index = models.CharField(max_length=25, blank=True)
