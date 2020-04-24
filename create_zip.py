import zipfile
import os
import shutil

def zipDir(dirpath, outFullName):
    zip = zipfile.ZipFile(outFullName, 'w', zipfile.ZIP_DEFLATED)
    for path, dirnames, filenames in os.walk(dirpath):
        fpath = path.replace(dirpath, '')
        for filename in filenames:
            zip.write(os.path.join(path, filename), os.path.join(fpath, filename))
    zip.close()

Asset_Name = '3H'
zipName = Asset_Name + '.zip'
DamageName = Asset_Name + '_Damage_View.obj'
Dir = 'C:\\Users\\luowe\\Cranfield University\\Li, Gen - Group Project\\Demonstration\\To Be Uploaded on Server_2'
Folder_Names = os.listdir(Dir)
FolderName_For_DamageView = Asset_Name + '_Thermo'

if Asset_Name in Folder_Names:
    if FolderName_For_DamageView not in os.listdir(os.path.join(Dir, Asset_Name)):
        os.makedirs(os.path.join(Dir, Asset_Name, FolderName_For_DamageView))
    shutil.move(os.path.join(Dir, Asset_Name, DamageName), os.path.join(Dir, Asset_Name, FolderName_For_DamageView))
    zipDir(os.path.join(Dir, Asset_Name), os.path.join(Dir, zipName))