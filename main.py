#Created by Evgeniy Vargin for learning

from tkinter import *
from frBaseEdtList import *
from connections import *

   
def main():
    try:
        cn = psycopg2.connect(dbname='administrator', user='administrator',password='Kartonka13', host='localhost')
        qry = PGQuery(cn,('key','name','position','age','salary','bonus'),"""SELECT key,name,position,age,salary,bonus FROM tb_employees """,Keyfield='key')
        #qry.execute()
        #ds = pd.read_sql_query("""SELECT key,name,position,age,salary,bonus FROM tb_employees """,cn,index_col='key').to_dict()
        #cur.execute("""SELECT key,name,position,age,salary,bonus FROM tb_employees """)
        #cur.fetchall()
        root = Tk()
        root.geometry("900x600")
        app = EdtGrid(root,qry.execute().to_dict(),cn,qry.getCursor(),'tb_employees',('string','key'))
        root.mainloop()
    finally:
        del qry
        cn.close
        #del ds
        
if __name__ == '__main__':
    main()
