//////////////////////////////////////////////////////////////////////////////////////
//
//    Copyright 2012 Adobe Systems Incorporated
//
//    This file is part of TMX to Moses Corpus Tool.
// 
//    TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Lesser General Public License as published by the 
//    Free Software Foundation, either version 3 of the License, or (at your option) 
//    any later version.
// 
//    TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
//    more details.
// 
//    You should have received a copy of the GNU Lesser General Public License along 
//    with TMX to Moses Corpus Tool.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////


package com.Adobe.managers
{
	import com.Adobe.util.XMLUtility;
	
	import flash.filesystem.*;
	
	import mx.charts.chartClasses.StackedSeries;
	import mx.messaging.channels.StreamingAMFChannel;

	public class ScriptMapManager
	{
		private static var _instance:ScriptMapManager;
		
		private var _scriptMap:XML = new XML();
		
		public function ScriptMapManager()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
			
		}
		
		public static function getInstance():ScriptMapManager
		{
			if (_instance == null){
				_instance = new ScriptMapManager();
			}
			return _instance;
		}
		
		public var mosesPath:String = "";
//		public var lmPath:String = "";
		public var lmFactor:String = "";
		public var lmOrder:String = "";
		public var corpusPath:String = "";
		public var trainingCorpusName:String = "";
		public var tuningCorpusName:String = "";
		public var testingCorpusName:String = "";
		public var srcLang:String = "";
		public var trgLang:String = "";
		public var alignOption:String = "";
		public var reorderOption:String = "";
		public var outputPath:String = "";
		
		
		public function getTrainingScript():String
		{
			var script:String = new String();
			
			var langPair:String = new String();
			
			langPair = srcLang.toUpperCase() + "_" + trgLang.toUpperCase();
			
			script += mosesPath + "/scripts/training/train-model.perl";
			script += " -scripts-root-dir " + mosesPath + "/scripts/ -root-dir " + outputPath + "/" + langPair + "/training";
			script += " -corpus " + corpusPath + "/" + langPair + "/training/" + trainingCorpusName;
			script += " -f " + srcLang + " -e " + trgLang;
			script += " -alignment " + alignOption;
			script += " -reordering " + reorderOption;
			script += " -lm " + lmFactor + ":" + lmOrder + ":" + outputPath + "/" + langPair + "/training/lm/LanguageModel.lm";
			
			return script;
		}
				
		public function getTuningScript():String
		{
			var script:String = new String();
			
			var langPair:String = new String();
			
			langPair = srcLang.toUpperCase() + "_" + trgLang.toUpperCase();
			
			script += mosesPath + "/scripts/training/mert-moses.pl ";
			script += corpusPath + "/" + langPair + "/tuning/" + tuningCorpusName + "." + srcLang + " ";
			script += corpusPath + "/" + langPair + "/tuning/" + tuningCorpusName + "." + trgLang + " ";
			script += mosesPath + "/bin/moses ";
			script += outputPath + "/" + langPair + "/training/model/moses.ini";
			script += " --mertdir " + mosesPath + "/bin/";
			script += " --working-dir " + outputPath + "/" + langPair + "/tuning/mert/";
			script += " --rootdir " + mosesPath + "/scripts/";
			script += " --decoder-flags \"-v 0\"\n";
			
			script += mosesPath + "/scripts/ems/support/reuse-weights.perl ";
			script += outputPath + "/" + langPair + "/tuning/mert/moses.ini";
			script += " < "	+ outputPath + "/" + langPair + "/training/model/moses.ini";
			script += " > " + outputPath + "/" + langPair + "/tuning/moses-tuned.ini";
			
			return script;
		}
	}
}