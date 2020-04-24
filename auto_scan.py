'''
This File is part of Cranfield University AR Project
auto_scan.py - The script to scan, sort and process raw file automatically

Copyright(c) 2020 Wei Luo, Cranfield University
Date: 2020/3/23

2020/4/20 change log:
Move .obj file to target folder and create .zip files
'''
import os
import sys
from _datetime import datetime
import shutil
import time
import matlab.engine
import tkinter as tk
from tkinter import filedialog
import tkinter.messagebox
import cv2 as cv
import zipfile

def zipDir(dirpath, outFullName):
    zip = zipfile.ZipFile(outFullName, 'w', zipfile.ZIP_DEFLATED)
    for path, dirnames, filenames in os.walk(dirpath):
        fpath = path.replace(dirpath, '')
        for filename in filenames:
            zip.write(os.path.join(path, filename), os.path.join(fpath, filename))
    zip.close()

non_process_list = []  #log system
file = ['TSRData.mat', '1stDerData.mat', '2ndDerData.mat']

print("Initializing...Please wait...")
eng = matlab.engine.start_matlab()
root = tk.Tk()
root.withdraw()
Dir = filedialog.askdirectory()
try:
    shutil.copy('./TSR_calculate_coefficient.exe', Dir)
    Dir = Dir + '/'
except IOError:
    sys.exit(1)

FolderToServer = 'C:\\Users\\luowe\\Cranfield University\\Li, Gen - Group Project\\Demonstration\\To Be Uploaded on Server_2' #Set Upload folder
ModelName = 'PeakTimeMap.obj'
ImageName = 'APTCMap.jpg'

while True:
    os.system('cls')
    if len(non_process_list) != 0:
        print("Non-processed list:" + '\n')
        for i in non_process_list:
            print(i + '\n')
    print("Scanning...")
    for name in os.listdir(Dir):
        if name.endswith('.RAW'):
            AssetName = input('RAW file detected, Please input asset name:')
            if AssetName not in os.listdir(FolderToServer) or AssetName + '.xml' not in os.listdir(os.path.join(FolderToServer, AssetName)) or AssetName + '.dat' not in os.listdir(os.path.join(FolderToServer, AssetName)):
                print('Warning: Cannot find target asset folder')
                os.makedirs(os.path.join(FolderToServer, AssetName))
            t = datetime.now().strftime('%Y-%m-%d_%H%M%S')
            PathName = Dir + t
            os.makedirs(PathName)
            shutil.move(Dir + name, PathName)
            FileName = name
            print('TSR calculating...')
            try:
                [x1, y1, result] = eng.TSR_calculate_coefficient(FileName, PathName, nargout=3)
            except:
                non_process_list.append(t)
            else:
                if result == 0:
                    non_process_list.append(t)
                else:
                    print('Calculating APTC and Confidence Map...')
                    [result, selection] = eng.APTC_and_Confidence(PathName, nargout=2)
                    if result == 0:
                        non_process_list.append(t)
                    else:
                        img = cv.imread(PathName + '/APTCMap.jpg')
                        cv.imshow('APTCMap', img)
                        cv.waitKey(0)
                        answer = tkinter.messagebox.askyesno('HDR', 'Do you want to select other ROIs and do HDR process to improve the quality of the image?')
                        if answer == True:
                            cv.destroyAllWindows()
                            FileName_HDR = file[int(selection)]
                            result = eng.APTC_HDR(PathName, FileName_HDR, nargout=1)
                            if result == 0:
                                non_process_list.append(t)
                        else:
                            cv.destroyAllWindows()
                        print('Calculating depth map...')
                        result = eng.PeakTimeMapping(PathName, x1, y1, nargout=1)
                        if result == 0:
                            non_process_list.append(t)
                if ModelName in os.listdir(PathName):
                    shutil.move(os.path.join(PathName, ModelName), os.path.join(FolderToServer, AssetName))
                    os.rename(os.path.join(FolderToServer, AssetName, ModelName), os.path.join(FolderToServer, AssetName, AssetName + '.obj'))
                if ImageName in os.listdir(PathName):
                    shutil.move(os.path.join(PathName, ImageName), os.path.join(FolderToServer, AssetName))
                    os.rename(os.path.join(FolderToServer, AssetName, ImageName), os.path.join(FolderToServer, AssetName, AssetName + '_Adaptive_peak_contrast_image.jpg'))

                FolderName_For_DamageView = AssetName + '_Thermo'
                if AssetName in os.listdir(FolderToServer):
                    if FolderName_For_DamageView not in os.listdir(os.path.join(FolderToServer, AssetName)):
                        os.makedirs(os.path.join(FolderToServer, AssetName, FolderName_For_DamageView))
                    shutil.move(os.path.join(FolderToServer, AssetName, AssetName + '.obj'), os.path.join(FolderToServer, AssetName, FolderName_For_DamageView))
                    zipDir(os.path.join(FolderToServer, AssetName), os.path.join(FolderToServer, AssetName + '.zip'))
    time.sleep(3)