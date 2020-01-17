#Created by Evgeniy Vargin for learning

from tkinter import *
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
        
    

class Grid(Frame):
    def __init__(self,Owner,Dataset):
        Frame.__init__(self,Owner)
        self.owner = Owner
        self.dataset = dictRectangle(Dataset)
        self.fields = {}
        for key in Dataset:
            self.fields[key] = key
        self.cont = Container()
        self.statusLabel = Label(self,text = 'Total: %s'%len(self.dataset))
        self.rebuild()

    def getStatus(self):
        return self.statusLabel['text']
    
    def setStatus(self,inText):
        self.statusLabel['text'] = inText
    
    def getStatusLabel(self):
        return self.statusLabel
    
    def getContainer(self):
        return self.cont
        
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
            self.cont.getItemByNum(rownum).append(self.dataset[key])
            e = []
            for (num,field) in enumerate(self.fields):
                #r.append(self.dataset[key].asDict()[field])
                ent = Entry(self)
                ent.grid(row = rownum + 1,column=num,padx=1,pady=1)
                ent.insert(0,self.dataset[key][field])
                e.append(ent)
            self.cont.getItemByNum(rownum).append(e)
            b = DmlBtn(self,Text='Save (%s)'%key,Rn=rownum)
            b.bind('<Button-1>',saveRecord)
            b.grid(row=rownum + 1,column=len(self.fields) + 1,padx=1,pady=1)
            self.cont.getItemByNum(rownum).append(b)
            
            d = DmlBtn(self,Text='Delete (%s)'%key,Rn=rownum)
            d.bind('<Button-1>',delRecord)
            d.grid(row=rownum + 1,column=len(self.fields) + 2,padx=1,pady=1)
            self.cont.getItemByNum(rownum).append(d)

def saveRecord(event):
    for (num,field) in enumerate(flds):
        setattr(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0],field,event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[1][num].get())
    event.widget.owner.setStatus(str(EmpShelve.setRow(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0])))

def delRecord(event):
    event.widget.owner.setStatus(EmpShelve.delRow(event.widget.owner.getContainer().getItemByNum(event.widget.getRn())[0].getKey()))
    

def main():
    try:
        #cn = pgSetConnect(inDB='administrator', inUser='administrator',inPwd='Kartonka13')
        cn = psycopg2.connect(dbname='administrator', user='administrator',password='Kartonka13', host='localhost')
        cur = cn.cursor()
        
        root = Tk()
        root.geometry("1200x600")
        #tbl = EmpShelve
        #ds = tbl.open()
        ds = pd.read_sql_query("""SELECT key,name,position,age||' years' AS age,salary,bonus FROM tb_employees """,cn,index_col='key').to_dict()
    
        #bob = tbl.setRow(Developer('bob','Bob Smith',42))
        #sue = tbl.setRow(Hardware('sue','Sue Johns',45))
        #tom = tbl.setRow(Manager('tom','Tom Kite',50,Salary=100000.0,Bonus=0.05))
        #john = tbl.setRow(Engineer('john','John Doe',42))
        #kate = tbl.setRow(DataScientist('kate','Kate Patrow',22))
    
        app = Grid(root,ds)
    
        root.mainloop()


        #key = 'sue'
        #cur.execute("""UPDATE tb_employees SET name = 'Sue Jones' WHERE key = '%s'"""%key)
        #cn.commit()
    
    finally:        
        del cur
        cn.close
        del ds
        
if __name__ == '__main__':
    main()

    """
    tbl = EmpTable
    print('*************** Table Begin ***************')
    db = tbl.open()
    for key in db:
        print(db[key])
    db.close()
    print('***************  Table End  ***************')
    """

