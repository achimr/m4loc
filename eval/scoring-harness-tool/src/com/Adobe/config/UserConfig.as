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


package com.Adobe.config
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;

	[Bindable]
	public class UserConfig extends EventDispatcher
	{
		private static var _instance:UserConfig;
		public function UserConfig()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
		}
		
		public static function getInstance():UserConfig{
			if (_instance == null){
				_instance = new UserConfig();
			}
			return _instance;
		}
		
		private var _bleuPath:String;
		private var _meteorPath:String;
		private var _terPath:String;
		
		public function set bleuPath(path:String):void
		{
			_bleuPath = path;
			dispatchEvent(new Event("bleuPathChanged"));
		}
		
		[Bindable(event="bleuPathChanged")]
		public function get bleuPath():String
		{
			return _bleuPath;
		}
		
		public function set meteorPath(path:String):void
		{
			_meteorPath = path;
			dispatchEvent(new Event("meteorPathChanged"));
		}
		
		[Bindable(event="meteorPathChanged")]
		public function get meteorPath():String
		{
			return _meteorPath;
		}
		
		public function set terPath(path:String):void
		{
			_terPath = path;
			dispatchEvent(new Event("terPathChanged"));
		}
		
		[Bindable(event="terPathChanged")]
		public function get terPath():String
		{
			return _terPath;
		}
		
	}
}