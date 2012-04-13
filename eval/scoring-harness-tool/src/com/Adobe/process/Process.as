package com.Adobe.process
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.*;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.ProgressBar;
	import mx.controls.TextArea;
	import mx.core.FlexGlobals;
	import mx.formatters.DateFormatter;
	import mx.managers.PopUpManager;
	
	public class Process
	{
		public function Process()
		{
			selfHeal();
		}
		
		private var process:NativeProcess = new NativeProcess();
		private var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
		private var progress_bar:ProgressBar = new ProgressBar();
		private var selfHealed:Boolean = false;
		private var scriptPortalPath:File = new File(File.applicationDirectory.resolvePath("scripts").nativePath);
		private var outputArea:mx.controls.TextArea = FlexGlobals.topLevelApplication.appUI.output;
		private var logFilePath:File = new File(File.documentsDirectory.resolvePath("MT_Evaluation").nativePath);
		private var logFile:File = new File();
				
		private function selfHeal():void
		{
//			progress_bar.labelPlacement = "center";
//			progress_bar.mode = "manual";
//			progress_bar.minimum = 0;
//			progress_bar.maximum = 100;
			
			if (NativeProcess.isSupported)
			{
				
				if (FlexGlobals.topLevelApplication.appUI.evalID.text != "")
				{
					logFile = new File(logFilePath.resolvePath(FlexGlobals.topLevelApplication.appUI.evalID.text + ".log").nativePath);
				}
				else
				{
					var timestamp:Date = new Date();
					var dateFormatter:DateFormatter = new DateFormatter();
					dateFormatter.formatString = "YYYYMMDDJJNNSS";
					logFile = new File(logFilePath.resolvePath(dateFormatter.format(timestamp) + ".log").nativePath);
				}
				
				var fileStream:FileStream = new FileStream();
				
				var file:File = new File("/bin/bash");
				
				processStartupInfo.executable = file;
				
//				processStartupInfo.workingDirectory = new File(File.userDirectory.nativePath);
				processStartupInfo.workingDirectory = scriptPortalPath;
				var args:Vector.<String> = new Vector.<String>();
				
				args.push("-s");
				
				processStartupInfo.arguments = args;
				
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, getError);
				process.addEventListener(ProgressEvent.STANDARD_INPUT_PROGRESS, sendInput);
				process.addEventListener(NativeProcessExitEvent.EXIT, onComplete);
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, getOutput);
				
				process.start(processStartupInfo);
				
				selfHealed = true;
				
				function getOutput(event:Event):void
				{
					outputArea.text += process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable).toString();
					
					fileStream.open(logFile, FileMode.WRITE);
					fileStream.writeUTFBytes(outputArea.text);
					fileStream.close();
				}
				
				function getError(event:Event):void
				{
					outputArea.text += process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable).toString();					
				}
				
				function sendInput(event:Event):void
				{
					process.closeInput();
				}
				
				function onComplete(event:Event):void
				{
					process.exit();
					
				}
			}
			else
			{
				trace("NativeProcess not supported.");
			}
			
		}
		
		/**
		 * Append message to the TextArea component on the display list.
		 * After appending text, call the setScroll() method which controls
		 * the scrolling of the TextArea.
		 */
		private function msg(value:String):void {
			outputArea.text += value;
			outputArea.dispatchEvent(new Event(Event.CHANGE));
			setTimeout(setScroll, 100);
		}
		
		/**
		 * Scroll the TextArea component to its maximum vertical scroll 
		 * position so that the TextArea always shows the last line returned
		 * from the server.
		 */
		private function setScroll():void {
			outputArea.verticalScrollPosition = outputArea.maxVerticalScrollPosition;
		}
		
		public function start(paraMeters:Array):void
		{
//			PopUpManager.addPopUp(progress_bar, DisplayObject(Application.application.appUI) as Sprite, true)
//			
//			PopUpManager.centerPopUp(progress_bar);
			
			if (selfHealed)
			{
//				var wrapScript:String     = scriptPortalPath.resolvePath("wrap-xml.perl").nativePath;
				var wrapScript:String  = scriptPortalPath.resolvePath("scoringHealer.py").nativePath;
				var refTemplate:String = scriptPortalPath.resolvePath("templates/refTemplate.xml").nativePath;
				var srcTemplate:String = scriptPortalPath.resolvePath("templates/srcTemplate.xml").nativePath;
				var tstTemplate:String = scriptPortalPath.resolvePath("templates/tstTemplate.xml").nativePath;
				
				var command:String = "";
				
				
				/////////////////////////////////////////////
				//Convert plaintext files to sgm for scoring
				//
//				command += "perl '" + wrapScript + "' '" + refTemplateSgm + "' " + paraMeters[1] + " < '" + paraMeters[3] + "' > '" + paraMeters[3] + ".xml'\n";
//				command += "perl '" + wrapScript + "' '" + srcTemplateSgm + "' " + paraMeters[0] + " < '" + paraMeters[4] + "' > '" + paraMeters[4] + ".xml'\n";
				for (var i:int = 0; i < paraMeters[7].length; i = i + 3)
				{
					command += "python '" + wrapScript + "' '" + paraMeters[5] + "' -t '" + refTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][i+1] + "(" + paraMeters[7][i+2] + ")'\n";
					command += "python '" + wrapScript + "' '" + paraMeters[6] + "' -t '" + srcTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][i+1] + "(" + paraMeters[7][i+2] + ")'\n";
					command += "python '" + wrapScript + "' '" + paraMeters[7][i] + "' -t '" + tstTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][i+1] + "(" + paraMeters[7][i+2] + ")'\n";
				}
				
				
				////////////////////
				//BLEU/NIST scoring
				//
				if ( paraMeters[2][0] && ( paraMeters[2][1] != "" ) )
				{
					command += "echo '<<<<<<<<<<<<<<<<<<<  BLEU  >>>>>>>>>>>>>>>>>>'\n\n"; 
					
					for (var j:int = 0; j < paraMeters[7].length; j = j + 3)
					{
						command += "python '" + wrapScript + "' '" + paraMeters[5] + "' -t '" + refTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][j+1] + "(" + paraMeters[7][j+2] + ")'\n";
						command += "python '" + wrapScript + "' '" + paraMeters[6] + "' -t '" + srcTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][j+1] + "(" + paraMeters[7][j+2] + ")'\n";
						command += "python '" + wrapScript + "' '" + paraMeters[7][j] + "' -t '" + tstTemplate + "' " + paraMeters[0] + " " + paraMeters[1] + " '" + paraMeters[7][j+1] + "(" + paraMeters[7][j+2] + ")'\n";
						command += "perl '" + paraMeters[2][1] + "' -r '" + paraMeters[5] + ".recased.xml' -s '" + paraMeters[6] + ".recased.xml' -t '" + paraMeters[7][j] + ".recased.xml'\n";
					}
				}
				
				
				////////////////////
				//METEOR scoring
				//
				if ( paraMeters[3][0] && ( paraMeters[3][1] != "" ) )
				{
					command += "echo '<<<<<<<<<<<<<<<<<<  METEOR  >>>>>>>>>>>>>>>>>>'\n\n"; 
					
					for (i = 0; i < paraMeters[7].length; i = i + 3)
					{
						command += "java -Dfile.encoding=UTF-8 -Xmx2G -jar '" + paraMeters[3][1] + "' '" + paraMeters[7][i] + ".recased.xml' '" + paraMeters[5] + ".recased.xml' -l " + paraMeters[1] + "\n";
					}
				}
				
				////////////////////
				//TER scoring
				//
				if ( paraMeters[4][0] && ( paraMeters[4][1] != "" ) )
				{
					command += "echo '<<<<<<<<<<<<<<<<<<<  TER  >>>>>>>>>>>>>>>>>'\n\n"; 
					
					for (i = 0; i < paraMeters[7].length; i = i + 3)
					{
						command += "java -Dfile.encoding=UTF-8 -jar '" + paraMeters[4][1] + "' -h '" + paraMeters[7][i] + ".recased.xml' -r '" + paraMeters[5] + ".recased.xml'\n";
					}
				}
				
				process.standardInput.writeUTFBytes(command);
			}
			else
			{
				PopUpManager.removePopUp(progress_bar);
			}
		}
		
		public function getLogList():ArrayCollection
		{
			var logListCollection:ArrayCollection = new ArrayCollection();
			var logList:Array = new Array();
			var fileListArr:Array = logFilePath.getDirectoryListing();
			var logPattern:RegExp = /.*\.log$/;
			
			for each (var file:File in fileListArr)
			{
				if ( (!file.isDirectory) && logPattern.test(file.name))
				{
					logList.push(file.name);
				}
			}
			
			logList.sort(Array.DESCENDING);
			
			logListCollection.source = logList;
			
			return logListCollection;
		}
		
		public function getLogContent(logFile:String):String
		{
			var content:String = new String();
			var fileStream:FileStream = new FileStream();
			
			fileStream.open(logFilePath.resolvePath(logFile), FileMode.READ);
			
			content = fileStream.readUTFBytes(fileStream.bytesAvailable);
			
			fileStream.close();
			
			return content;
		}
	}
}