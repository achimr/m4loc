## Translation Scoring Harness ##
The Scoring Tool is used to evaluate documents translated by MT engine(s).  It uses common scoring methods such as BLEU/NIST, METEOR and TER. You can choose one or more scoring methods as needed. The result of each evaluation is stored on server for later comparison and analysis. The UI of this tool is shown below.


**Specify Evaluation Name** You are required to enter a name for your current evaluation as the evaluation results are organized by name on the server. If the same name already exists on the server, all of its data will be overwritten by current evaluation.


**Specify Source & Target Languages**


**Choose Scoring Method(s)** Before selecting scoring method(s), you need to download their scripts to your local computer. You can download the scoring routines from the addresses below.


**BLEU/NIST** [ftp://jaguar.ncsl.nist.gov/mt/resources/mteval-v13a.pl](ftp://jaguar.ncsl.nist.gov/mt/resources/mteval-v13a.pl)

---

**METEOR** http://www.cs.cmu.edu/~alavie/METEOR/download/meteor-1.3.tgz

---

**TER** http://www.cs.umd.edu/~snover/tercom/tercom-0.7.25.tgz

---


**Specify Source & Reference File Source
File refers to the document of source language. Reference file refers to the human-translated document which you want to use as the scoring standard.**


**Add File(s) to Evaluate Target file**  Refers to the document translated by the MT engine. You can add as many documents as needed but you're required to input an ID for each of them in order to display the evaluation results.


**View Log** All evaluation results are stored on the server. You can retrieve them for comparison or analysis at any time. The results can be represented by two modes: