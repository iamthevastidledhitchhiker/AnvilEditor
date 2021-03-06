/*
	Author: Will Hart

	Description:
	  Creates a new mission, where a site must be captured and cleared of enemy

	Parameter(s):
	  _this select 0: OBJECT, the objective being created
	  _this select 1: FUNCTION, the function to call when the EOS mission completes
	  _this select 2: FUNCTION, the function to call when the objective has been completed

	Example:
	  [objective, AFW_fnc_NOP, AFW_fnc_NOP] call AFW_fnc_Mission_Capture;
	
	Returns:
	  Nothing
*/

#include "defines.sqf"

private ["_eosCB", "_CB", "_obj", "_obj_name"];

_obj = _THIS(0);
_eosCB = _THIS(1);
_CB = _THIS(2);
_obj_name = O_OBJ_NAME(_obj);

// spawn the objective
[_obj, _eosCB] spawn AFW_fnc_doEosSpawn;

waitUntil { sleep 5; server getVariable _obj_name };

_obj spawn _CB;