#Created by Evgeniy Vargin for learning

from tkinter import *

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
        self.pack(fill=BOTH,expand=1)
        self.columnconfigure(len(self.fields),weight=1)
        self.rowconfigure(len(self.dataset) + 1,weight=1)
        
        rownum = self.cont.addItem([])
        for (num,key) in enumerate(self.fields):
            self.cont.getItemByNum(rownum).append(Label(self,text=self.fields[key],font = "Calibri 11 bold").grid(row = 0,column=num))
        for (idx,key) in enumerate(self.dataset):
            rownum = self.cont.addItem([])
            self.cont.getItemByNum(rownum).append(self.dataset[key])
            e = []
            for (num,field) in enumerate(self.fields):
                #r.append(self.dataset[key].asDict()[field])
                ent = Entry(self)
                ent.grid(row = idx+1,column=num)
                ent.insert(0,self.dataset[key][field])
                ent.config(state='readonly')
                e.append(ent)
            self.cont.getItemByNum(rownum).append(e)

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
