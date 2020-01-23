#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 10 23:06:35 2020

@author: administrator
"""

import psycopg2
import pandas as pd

connections = []

class PGQuery():
    def __init__(self,Conn,Fields,SelectSQL,MergeSQL=None,DeleteSQL=None,Keyfield=None,SelectParams=None,MergeParams=None,DeleteParams=None):
        self.conn = Conn
        self.cursor = self.conn.cursor()
        self.fields = Fields
        self.selectsql = SelectSQL
        self.mergesql = MergeSQL
        self.deletesql = DeleteSQL
        self.keyfield = Keyfield
        self.selectparams = SelectParams
        self.mergeparams = MergeParams
        self.deleteparams = DeleteParams
        print(self.mergesql)
    
    def execute(self):
        return pd.read_sql_query(sql=self.selectsql,con=self.conn,index_col=self.keyfield,coerce_float=True,params=self.selectparams,parse_dates=None,chunksize=None)
        
    def getCursor(self):
        return self.cursor
    
    def setSelectSQL(self,SelectSQL):
        self.selectsql = SelectSQL

    def getSelectSQL(self):
        return self.selectsql

    def setMergeSQL(self,MergeSQL):
        self.mergesql = MergeSQL

    def getMergeSQL(self):
        return self.mergesql

    def setDeleteSQL(self,DeleteSQL):
        self.deletesql = DeleteSQL

    def getDeleteSQL(self):
        return self.deletesql
    
    def setSelectParams(self,SelectParams):
        self.selectparams = SelectParams
    
    def getSelectParams(self):
        return self.selectparams

    def setMergeParams(self,MergeParams):
        self.mergeparams = MergeParams
    
    def getMergeParams(self):
        return self.mergeparams

    def setDeleteParams(self,DeleteParams):
        self.deleteparams = DeleteParams
    
    def getDeleteParams(self):
        return self.deleteparams

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