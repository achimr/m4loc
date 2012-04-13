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


package com.Adobe.events
{
	import flash.events.Event;
	
	public class StepEvent extends Event
	{
		public static var Step_Order_Changed:String = "StepOrderChanged";
		public static var Step_State_Changed:String = "StepStateChanged";
		public static var Step_Parameter_Changed:String = "StepParameterChanged";
		
		public var parameters:Array = new Array();
		
		public function StepEvent(type:String, parameters:Array=null, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.parameters = parameters;
		}
		
		override public function clone():Event
		{
			var event:StepEvent = new StepEvent(Step_Order_Changed);
			return event;
		}
		
	}
}