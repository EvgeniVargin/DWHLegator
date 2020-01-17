#Created by Evgeniy Vargin for learning

from tkinter import *
from frBaseList import *
   
def main():
    try:
        cn = psycopg2.connect(dbname='administrator', user='administrator',password='Kartonka13', host='localhost')
        cur = cn.cursor()
        root = Tk()
        root.geometry("1200x600")
        ds = pd.read_sql_query("""SELECT key,name,position,age||' years' AS age,salary,bonus FROM tb_employees """,cn,index_col='key').to_dict()
        app = MainGrid(root,ds)
        root.mainloop()
    finally:        
        del cur
        cn.close
        del ds
        
if __name__ == '__main__':
    main()
