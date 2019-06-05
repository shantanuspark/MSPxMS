import os, sys
from flask import Flask, render_template, request, jsonify
from werkzeug import secure_filename
import random
import subprocess
import pandas as pd


app = Flask(__name__)

@app.route('/')
def render_index():
   return render_template('index.html')

def randomDigits(digits):
    lower = 10**(digits-1)
    upper = 10**digits - 1
    return random.randint(lower, upper)
	
@app.route('/upload-long-file', methods = ['POST'])
def upload_long_file():
   try:
      f = request.files['longFile']
      long_filename = str(randomDigits(9))+f.filename
      f.save('data/'+secure_filename(long_filename))
      return jsonify(long_filename)
   except:
      return 'Long file upload Error', 400

@app.route('/upload-short-file', methods = ['POST'])
def upload_short_file():
   try:
      f = request.files['shortFile']
      short_filename = str(randomDigits(9))+f.filename
      f.save('data/'+secure_filename(short_filename))
      return jsonify(short_filename)
   except:
      return 'Short file upload Error', 400
   return filename.split('.')[0]

@app.route('/execute/<long_filename>/<short_filename>', methods = ['POST'])
def execute(long_filename, short_filename):
   pt_1 = request.form.get('pt_1')
   pt_2 = request.form.get('pt_2')
   et_1 = request.form.get('et_1')
   et_2 = request.form.get('et_2')
   print(long_filename, short_filename, pt_1, pt_2, et_1, et_2)
   op_filename = str(randomDigits(9))+'.tsv'
   subprocess.call(['C:/Strawberry/perl/bin/perl.exe', './prepare_report.pl', 'data/'+long_filename, 'data/'+short_filename, pt_1, pt_2, et_1, et_2, 'data/'+op_filename])
   return jsonify(op_filename)

@app.route('/clean/<longFile>/<shortFile>/<resultFile>', methods = ['GET'])
def clean(longFile,shortFile,resultFile):
   os.remove('data/'+longFile)
   os.remove('data/'+shortFile)
   os.remove('data/'+resultFile+'.tsv')
   return jsonify(True)

@app.route('/get_content/<file_name>', methods = ['GET'])
def read_output(file_name):
   df = pd.read_csv('data/'+file_name+'.tsv', delimiter='\t', index_col=False)
   print(df.head())
   df.columns = ['AccNumber','Sequence Fragment',
      'Occurrences By Time','Occurances in Experimental NEC','Occurrences in NEC',	
      'Best Experimental Score','Best NEC Score', 'a', '0015','0060','0240','b']
   return df.to_json(orient='records')

	
@app.route('/generate_structure/<file_name>', methods = ['POST'])
def create_2dStructure(file_name):
   sequence = request.get_json()
   with open("uploaded_sequences/"+file_name+".fasta", "w") as output_handle:
      output_handle.write(">repeat\n"+sequence['seq'])

   if os.path.isfile('uploaded_sequences/'+file_name+'.fasta'):
      print('file found', 'uploaded_sequences/'+file_name+'.fasta')
      subprocess.call(['C:\Program Files\RNAstructure6.1\exe\Fold', 'uploaded_sequences/'+file_name+'.fasta', 'uploaded_sequences/'+file_name+'.ct',
       '--DNA', '--loop' , '30', '--maximum', '20', '--percent', '10', '--temperature', '310.15', '--window', '3'])
   else:
      raise Exception()

   if os.path.isfile('uploaded_sequences/'+file_name+'.ct'):
      subprocess.call(['C:\Program Files\RNAstructure6.1\exe\draw', 'uploaded_sequences/'+file_name+'.ct', 'static/logos/'+file_name+'.svg',
       '--svg', '-n' , '1'])
   else:
      raise Exception()

   return jsonify('{"success":1}')

if __name__ == '__main__':
   app.run(host='0.0.0.0', debug=True, port=5000)
  