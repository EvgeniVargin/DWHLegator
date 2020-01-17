#Created by Evgeniy Vargin for learning

from tkinter import *
from connections import *
'''
tst = {}
for x in range(3):
    rw = {}
    for y in range(4):
        rw[y] = 'Cell %s %s'%(y,x)
    tst[x] = rw
'''
class DmlBtn(Button):
    def __init__(self,Owner,Text,Rn):
        Button.__init__(self,Owner,text=Text)
        self.owner = Owner
        self.text = Text
        self.rn = Rn
    
    def getRn(self):
        return self.rn

class Container:
    def __init__(self):
        self.items = []
    
    def items(self):
        return self.items
    
    def addItem(self,obj):
        self.items.append(obj)
        return len(self.items) - 1
    
    def getItemByNum(self,num):
        try:
            return self.items[num]
        except:
            return None
    
    def getItemAsString(self,num):
        try:
            return str(self.items[num])
        except:
            return None
    
    def clear(self):
        self.items.clear()
        
    

class EdtGrid(Frame):
    def __init__(self,Owner,Dataset,Connection,Cursor,Table,KeyField):
        Frame.__init__(self,Owner)
        self.owner = Owner
        self.dataset = dictRectangle(Dataset)
        self.fields = {}
        for key in Dataset:
            self.fields[key] = key
        self.cont = Container()
        self.statusLabel = Label(self,text = 'Total: %s'%len(self.dataset))
        self.table = Table
        self.keyfield = KeyField
        self.connection = Connection
        self.cursor = Cursor
        self.rebuild()

    def getStatus(self):
        return self.statusLabel['text']
    
    def setStatus(self,inText):
        self.statusLabel['text'] = inText
    
    def getStatusLabel(self):
        return self.statusLabel
    
    def getContainer(self):
        return self.cont
    
    def getConnection(self):
        return self.connection
    
    def getCursor(self):
        return self.cursor
    
    def getTable(self):
        return self.table
    
    def getKeyField(self):
        return self.keyfield
        
    def rebuild(self):
        tk = self.owner
        tk.title("Список сотрудников:")
        self.pack(fill=BOTH,expand=1)
        self.columnconfigure(len(self.fields) + 3,weight=1)
        self.rowconfigure(len(self.dataset) + 2,weight=1)
        self.getStatusLabel().grid(row=0,column=0,padx=1,pady=1,columnspan=len(self.fields) + 2,sticky=W)
        
        rownum = self.cont.addItem([])
        for (num,key) in enumerate(self.fields):
            self.cont.getItemByNum(rownum).append(Label(self,text=self.fields[key],font="Arial 11 bold").grid(row = 1,column=num,padx=1,pady=1))
        for (idx,key) in enumerate(self.dataset):
            rownum = self.cont.addItem([])
            self.cont.getItemByNum(rownum).append(key)
            e = []
            for (num,field) in enumerate(self.fields):
                #r.append(self.dataset[key].asDict()[field])
                ent = Entry(self)
                ent.grid(row = rownum + 1,column=num,padx=1,pady=1)
                ent.insert(0,self.dataset[key][field])
                e.append(self.dataset[key][field])
            self.cont.getItemByNum(rownum).append(e)
            b = DmlBtn(self,Text='Save (%s)'%key,Rn=rownum)
            b.bind('<Button-1>',saveRecord)
            b.grid(row=rownum + 1,column=len(self.fields) + 1,padx=1,pady=1)
            self.cont.getItemByNum(rownum).append(b)
            
            d = DmlBtn(self,Text='Delete (%s)'%key,Rn=rownum)
            d.bind('<Button-1>',delRecord)
            d.grid(row=rownum + 1,column=len(self.fields) + 2,padx=1,pady=1)
            self.cont.getItemByNum(rownum).append(d)
    
    def refresh(self):
        self.cont.clear()
        #self.dataset = dictRectangle(Dataset.)

def saveRecord(event):
    print(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0])
    
    #for (num,field) in enumerate(flds):
    #    setattr(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0],field,event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[1][num].get())
    #event.widget.owner.setStatus(str(EmpShelve.setRow(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0])))

def delRecord(event):
    try:
        if event.widget.owner.getKeyField()[0] in ('string','date'):
            keyvalue = "'%s'"%event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0]
        else:
            keyvalue = event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0]
        dml = 'DELETE FROM %s WHERE %s = %s'%(event.widget.owner.getTable(),event.widget.owner.getKeyField()[1],keyvalue)
        #print(dml)
        event.widget.owner.getCursor().execute(dml)
        event.widget.owner.getConnection().commit()
        event.widget.owner.refresh()
    except:
        print('ERROR')