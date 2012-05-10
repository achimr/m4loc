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


package com.Adobe.file
{
	import com.degrafa.core.degrafa_internal;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	import mx.controls.ProgressBar;
	import mx.core.Application;
	import mx.managers.PopUpManager;
	import mx.messaging.channels.StreamingAMFChannel;
	
	public class FileUtil extends EventDispatcher
	{
		public function FileUtil(lingDir:String, projName:String, srcLang:String, targLangs:Array)
		{
			this._lingDir = new File(lingDir);
			this._projName = projName;
			this._srcLang = srcLang;
			this._targLangs = targLangs;
			
			selfHeal();
		}
		
		private var _lingDir:File;
		private var _projName:String = "";
		private var _srcLang:String = "";
		private var _targLangs:Array = new Array();
		
		private var process:NativeProcess = new NativeProcess();
		private var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		private var selfHealed:Boolean = false;
		
		private var progress_bar:ProgressBar = new ProgressBar();
		
		private function selfHeal():void
		{
			progress_bar.labelPlacement = "center";
			progress_bar.mode = "manual";
			progress_bar.minimum = 0;
			progress_bar.maximum = 100;
			
			for each (var targLang:String in _targLangs)
			{
//				var basePath:String = _projName + "/" + _srcLang.toUpperCase() + "-" + targLang.toUpperCase() + "/Corpus.";
//				
//				var morsesSrcFile:File = _lingDir.resolvePath(basePath + _srcLang.substring(0,2).toLowerCase());
//				var morsesTargFile:File = _lingDir.resolvePath(basePath + targLang.substring(0,2).toLowerCase());
//				
//				if (morsesSrcFile.exists) morsesSrcFile.deleteFile();
//				if (morsesTargFile.exists) morsesTargFile.deleteFile();
				var corpusPath:String = _projName + "/" + _srcLang.toUpperCase() + "-" + targLang.toUpperCase();
				
				var corpusFile:File = _lingDir.resolvePath(corpusPath);
				
				if (corpusFile.exists) corpusFile.deleteDirectory(true);
			}
			
			if (NativeProcess.isSupported)
			{
				var file:File = new File("/bin/bash");
				
				processStartupInfo.executable = file;
				
				processStartupInfo.workingDirectory = new File(File.userDirectory.nativePath);
				var args:Vector.<String> = new Vector.<String>();
				
				args.push("-s");
				
//				var arg:String = "/home/moses/nlp-moses/tools/scripts/tokenizer.perl -l " + srcLang + " < " + morsesSrcFile.nativePath + " > " + morsesSrcMidFile.nativePath;
//				
//				args.push("-c");
//				args.push(arg);
				
				processStartupInfo.arguments = args;
				
//				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, getError);
				process.addEventListener(ProgressEvent.STANDARD_INPUT_PROGRESS, sendInput);
				process.addEventListener(NativeProcessExitEvent.EXIT, onComplete);
//				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, getOutput);
				
				process.start(processStartupInfo);
				
				selfHealed = true;
				
				function getOutput(event:Event):void
				{
					Alert.show(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable));
				}
				
				function getError(event:Event):void
				{
					Alert.show(process.standardError.readUTFBytes(process.standardError.bytesAvailable));
				}
				
				function sendInput(event:Event):void
				{
					process.closeInput();
				}
				
				function onComplete(event:Event):void
				{
					PopUpManager.removePopUp(progress_bar);

					process.exit();
				}
			}
			else
			{
				trace("NativeProcess not supported.");
			}

		}
		
		public function convert(tmxFiles:Array, steps:Array):void
		{
			addEventListener("splitCompleted", callScripts);
			
			for (var i:uint = 0; i < tmxFiles.length; i ++)
			{
//				split(tmxFiles[i], steps[0], steps[1], !Boolean(tmxFiles.length-i-1));
				split(tmxFiles[i], true, true, !Boolean(tmxFiles.length-i-1));
			}
			
			function callScripts(event:Event):void
			{
				removeEventListener("splitCompleted", callScripts);
				
				if (selfHealed)
				{
					progress_bar.label = "Cleaning Corpus files...";
					
//					var scripts:Array = new Array("tokenizer.perl", "detoken.py", "lowercase.perl", "extra-long-clean.py", "numcleaner.py", "dupcleaner.py", "weird-align-clean.py");
//					
//					var selectedScripts:Array = new Array();
//					
//					for (var i:int = 2; i < steps.length; i ++)
//					{
//						if (steps[i])
//						{
//							selectedScripts.push(scripts[i-2]);
//						}
//					}
					
					var commands:String = new String();
					
					for each (var lang:String in _targLangs)
					{
						commands += generateScripts(steps, _srcLang, lang);
					}
					
					process.standardInput.writeUTFBytes(commands);				
				}
				else
				{
					PopUpManager.removePopUp(progress_bar);
				}
			}
		}
				
		//Step 1. Split TMX files to 2 Moses Corpus files
		//        Input Encoding: UTF16
		//        Output Encoding: UTF8
		private function split(tmxFile:File, clnPH:Boolean, clnURL:Boolean, ifLastFile:Boolean):void
		{
			//reg exp of <ph> tag pairs
			var ptnPH:RegExp = /<ph.? *(id="\d+")*.? *(x=".*?")*>(\{\d+\})<\/ph>/gism;
			
			//reg exp of <seg> tag pairs
			var ptnSeg:RegExp = /<seg>( *)(.*)<\/seg>/g;
			
			//reg exp of extra line breaks
			var ptnBrk:RegExp = /(\n)+/g;
			
			//reg exp of extra white spaces
//			var ptnSpace:RegExp = / {2,}/g;
			
			//reg exp of URLs
			var ptnURL:RegExp = /(http:\/\/)?(\w)+\.(\w)+\.(\w)+(\/[^ \{\}]+)*/g;
			
			var newTMX:String = new String();
			
//			var fileStream:FileStream = new FileStream();
//			fileStream.open(tmxFile, FileMode.READ);
//			
//			newTMX = fileStream.readUTFBytes(fileStream.bytesAvailable);
//			
//			fileStream.close();

			PopUpManager.addPopUp(progress_bar, DisplayObject(Application.application.appUI) as Sprite, true)
			
			PopUpManager.centerPopUp(progress_bar);
			
			var TMX_URL:String = tmxFile.nativePath;
			
			var TMX_URL_REQ:URLRequest = new URLRequest("file://"+TMX_URL);
			
			var tmxLoader:URLLoader = new URLLoader();
			
			tmxLoader.addEventListener(ProgressEvent.PROGRESS, onFileLoadInProgress);
			tmxLoader.addEventListener(Event.COMPLETE, onFileLoadComplete);
			
			tmxLoader.load(TMX_URL_REQ);
			
			function onFileLoadInProgress(event:ProgressEvent):void{
				
				var loadPercent:uint = event.bytesLoaded / event.bytesTotal * 100;
				
				progress_bar.setProgress(loadPercent,100);
				
				progress_bar.label = "Loading " + tmxFile.name + "..." + loadPercent + "%";
			}
			
			function onFileLoadComplete(event:Event):void
			{				
				progress_bar.label = "Splitting " + tmxFile.name + "...";
				tmxLoader.removeEventListener(ProgressEvent.PROGRESS, onFileLoadInProgress);
				tmxLoader.removeEventListener(Event.COMPLETE, onFileLoadComplete);
				
				newTMX = event.target.data;
				
				if ( clnPH ) newTMX = newTMX.replace(ptnPH, "$3");
				
				for each (var lang:String in _targLangs)
				{
					splitEachLang(lang);
				}
				
				if (ifLastFile) dispatchEvent(new Event("splitCompleted"));
			}
			
			function splitEachLang(targLang:String):void
			{
				var basePath:String = _projName + "/" + _srcLang.toUpperCase().replace(/\-/, '_') + "-" + targLang.toUpperCase().replace(/\-/, '_') + "/Corpus.";
								
				var morsesSrcFile:File = _lingDir.resolvePath(basePath + _srcLang.substring(0,2).toLowerCase());
				var morsesTargFile:File = _lingDir.resolvePath(basePath + targLang.substring(0,2).toLowerCase());
				
				var morsesSrcBakFile:File = _lingDir.resolvePath(basePath + _srcLang.substring(0,2).toLowerCase()+".bak");
				var morsesTargBakFile:File = _lingDir.resolvePath(basePath + targLang.substring(0,2).toLowerCase()+".bak");
//				if (morsesSrcFile.exists) morsesSrcFile.deleteFile();
//				if (morsesTargFile.exists) morsesTargFile.deleteFile();
				
				var srcFileStream:FileStream = new FileStream();
				var targFileStream:FileStream = new FileStream();
				
				var srcSeg:String = new String();
				var targSeg:String = new String();
				
				srcFileStream.open(morsesSrcFile, FileMode.APPEND);
				targFileStream.open(morsesTargFile, FileMode.APPEND);
				
				for each (var unit:XML in XML(newTMX).descendants("tu"))
				{
					if (unit.descendants("tuv")[1].attributes().toString().indexOf(targLang) != -1)
					{
						srcSeg = unit.descendants("tuv")[0].seg.toString().replace(ptnBrk, " ");
						targSeg = unit.descendants("tuv")[1].seg.toString().replace(ptnBrk, " ");
						
	//					srcSeg = srcSeg.replace(ptnSpace, " ");
	//					targSeg = targSeg.replace(ptnSpace, " ");
						
						srcSeg = srcSeg.replace(ptnSeg, "$2");
						targSeg = targSeg.replace(ptnSeg, "$2");
						
						if (clnURL)
						{
							srcSeg = srcSeg.replace(ptnURL, "");
							targSeg = targSeg.replace(ptnURL, "");						
						}
						
						srcFileStream.writeUTFBytes(srcSeg+"\n");
						targFileStream.writeUTFBytes(targSeg+"\n");
					}
				}
				
				srcFileStream.close();
				targFileStream.close();
				
				morsesSrcFile.copyTo(morsesSrcBakFile, true);
				morsesTargFile.copyTo(morsesTargBakFile, true);
				
			}
		}
								
		private function generateScripts(cmds:Array, srcLang:String, targLang:String):String
		{
			var basePath:String = _projName + "/" + _srcLang.toUpperCase().replace(/\-/, '_') + "-" + targLang.toUpperCase().replace(/\-/, '_') + "/Corpus.";
			
			var morsesSrcFile:File = _lingDir.resolvePath(basePath + _srcLang.substring(0,2).toLowerCase());
			var morsesTargFile:File = _lingDir.resolvePath(basePath + targLang.substring(0,2).toLowerCase());
			
			var morsesSrcMidFile:File = _lingDir.resolvePath(basePath + "mid." + _srcLang.substring(0,2).toLowerCase());
			var morsesTargMidFile:File = _lingDir.resolvePath(basePath + "mid." + targLang.substring(0,2).toLowerCase());
			
//			var mosesDir:File = new File(mosesPath);
			
			var input:String = new String();
			
			for each (var cmd:Object in cmds)
			{
				var scriptPath:String = File.applicationDirectory.resolvePath("scripts/"+cmd.scriptName).nativePath;
				var parameter:String = new String();
				
				switch(cmd.scriptName)
				{
					case "tokenizer.perl":
						input += "perl " + scriptPath + " -l " + srcLang.substr(0,2) + " < " + morsesSrcFile.nativePath + " > " + morsesSrcMidFile.nativePath + "\n";
						input += "perl " + scriptPath + " -l " + targLang.substr(0,2) + " < " + morsesTargFile.nativePath + " > " + morsesTargMidFile.nativePath + "\n";
						input += "mv " + morsesSrcMidFile.nativePath + " " + morsesSrcFile.nativePath + "\n";
						input += "mv " + morsesTargMidFile.nativePath + " " + morsesTargFile.nativePath + "\n";
						break;
					case "lowercase.perl":
						input += "perl " + scriptPath + " < " + morsesSrcFile.nativePath + " > " + morsesSrcMidFile.nativePath + "\n";
						input += "perl " + scriptPath + " < " + morsesTargFile.nativePath + " > " + morsesTargMidFile.nativePath + "\n";
						input += "mv " + morsesSrcMidFile.nativePath + " " + morsesSrcFile.nativePath + "\n";
						input += "mv " + morsesTargMidFile.nativePath + " " + morsesTargFile.nativePath + "\n";
						break;
					case "detoken.py":
					case "numcleaner.py":
						input += "python " + scriptPath + " < " + morsesSrcFile.nativePath + " > " + morsesSrcMidFile.nativePath + "\n";
						input += "python " + scriptPath + " < " + morsesTargFile.nativePath + " > " + morsesTargMidFile.nativePath + "\n";
						input += "mv " + morsesSrcMidFile.nativePath + " " + morsesSrcFile.nativePath + "\n";
						input += "mv " + morsesTargMidFile.nativePath + " " + morsesTargFile.nativePath + "\n";
						break;
					case "extra-long-clean.py":
						parameter = "";
						if ( cmd.parameters[0] != 0 ) parameter += ' -s ' + cmd.parameters[0];
						if ( cmd.parameters[1] != 0 ) parameter += ' -t ' + cmd.parameters[1];
						input += "python " + scriptPath + parameter + " " + morsesSrcFile.nativePath + " " + morsesTargFile.nativePath + "\n";
						break;
					case "dupcleaner.py":
						input += "python " + scriptPath + "\n";
						break;
					case "weird-align-clean.py":
						parameter = "";
						if ( cmd.parameters[0] != 0 ) parameter += cmd.parameters[0];
//						if ( paras[3] != 0 ) parameter += ' -g ' + paras[3];
//						if ( paras[4] != 0 ) parameter += ' -l ' + paras[4];
//						input += "python " + scriptPath + parameter + " " + morsesSrcFile.nativePath + " " + morsesTargFile.nativePath + "\n";
						input += "python " + scriptPath + " " + morsesSrcFile.nativePath + " " + morsesTargFile.nativePath + " " + parameter + "\n";
						break;
				}
			}
			
			return input;
		}
		
//		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
//		{
//		}
//		
//		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
//		{
//		}
//		
//		public function dispatchEvent(event:Event):Boolean
//		{
//			return false;
//		}
//		
//		public function hasEventListener(type:String):Boolean
//		{
//			return false;
//		}
//		
//		public function willTrigger(type:String):Boolean
//		{
//			return false;
//		}
	}
}