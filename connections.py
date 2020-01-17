#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 10 23:06:35 2020

@author: administrator
"""

import psycopg2
import pandas as pd

connections = []

def dictRectangle(inDict):
    result = {}
    #Сформируем список всех Ид
    ids = []
    for (x,xkey) in enumerate(inDict):
        if x > 0:
            break
        for ykey in inDict[xkey]:
            ids.append(ykey)
    #Сформируем словарь с пустыми словарями
    for rw in ids:
        result[rw] = {}
    #Заполним пустую матрицу значениями
    for rw in ids:
        for col in inDict:
            result[rw][col] = inDict[col][rw]
    return result

def pgSetConnect(inDB,inUser,inPwd,inHost='localhost'):
    connections.append(psycopg2.connect(dbname=inDB, user=inUser,password=inPwd, host=inHost))
    #connections[len(connections) - 1].row_factory = dict_factory
    return connections[len(connections) - 1]
        
def getConnect(num):
    return connections[num]

def closeConnect(num):
    connections[num].close()