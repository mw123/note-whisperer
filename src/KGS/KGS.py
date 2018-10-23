import pymysql
pymysql.install_as_MySQLdb()
import MySQLdb

from config import *

alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ+0123456789.abcdefghijklmnopqrstuvwxyz"

def perm_string(word, iters=1000000):
	results = []

	idx1 = alphabet.index(word[0])
	idx2 = alphabet.index(word[1])
	idx3 = alphabet.index(word[2])
	idx4 = alphabet.index(word[3])
	idx5 = alphabet.index(word[4])

	while idx1 < len(alphabet):
		while idx2 < len(alphabet):
			while idx3 < len(alphabet):
				while idx4 < len(alphabet):
					while idx5 < len(alphabet):
						key = ''.join([alphabet[idx1],alphabet[idx2],alphabet[idx3],alphabet[idx4],alphabet[idx5]])
						results.append((key, False))
						if len(results) > iters:
							return results
						idx5 += 1
					idx5 = 0
					idx4 += 1
				idx4 = 0
				idx3 += 1
			idx3 = 0
			idx2 += 1
		idx2 = 0
		idx1 += 1
	return results

db = MySQLdb.connect(host=DB_HOST, user=DB_USER, passwd=DB_PASSWD, 
						db=DB_NAME, cursorclass=MySQLdb.cursors.DictCursor)  

try:
	with db.cursor() as cur:
		cur.execute('CREATE TABLE IF NOT EXISTS url_keys(id INT(11) AUTO_INCREMENT PRIMARY KEY, url_key CHAR(5), used BOOLEAN);')

	key = "A+0.a"
	while key[0] != "z":
		row_data = perm_string(key)
		key = row_data.pop()[0]
		
		with db.cursor() as cur:
			cur.executemany('INSERT INTO url_keys (url_key, used) VALUES(%s, %s)', row_data)
			db.commit()
		row_data = []
		
except MySQLdb.Error as e:
	try:
		print("MySQL Error [{}]: {}".format(e.args[0], e.args[1]))
	except IndexError:
		print("MySQL Error: {}".format(str(e)))
finally:
	db.close()

