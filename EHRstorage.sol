pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

contract Healthrecord {
      mapping (bytes32 => uint[]) variants; //key = variant
      mapping (bytes32 => uint[]) patientIDs; //key = patientID
      mapping (string => uint[]) MedHxs; //key = MedHx

      mapping (uint => PatientDataStruct) database;
      uint counter;
     UniqueObservations[] uniqueObservationsArray;
     
    struct ObservationReturnStruct {
        string variant;
        uint grade;
        uint patientID;
        uint age;
        string MedHx;
    }
    
    struct PatientDataStruct {
        bytes32 variantField;
        bytes32 gradeField;
        bytes32 patientIDField;
        bytes32 ageField;
        string MedHxField;
        uint index;
        address whoAdded;
    }
   
    struct UniqueObservations {
    	bytes32 variant;
    	bytes32 patientID;
    	string MedHx;
    }
   
    struct FieldQueries {
        bool variantID;
        bool patientIDNumber;
        bool drug;
    }

    function insertRecord (
        string memory variant,
        uint grade,
        uint patientID,
        uint age,
        string memory MedHx
    ) public {
        bytes32 name = stringToBytes32(variant);
        bytes32 grading = stringToBytes32(intToString(grade));
        bytes32 patientIDNumber = stringToBytes32(intToString(patientID));
        bytes32 age_score = stringToBytes32(intToString(age));
        //bytes32 IPFS_hash = ipfsHash;
        address who = msg.sender;

        if (observationExists(variant, intToString(patientID), MedHx) == false) {
            uniqueObservationsArray.push(UniqueObservations(name, patientIDNumber, MedHx));
        }
        
        variants[name].push(counter);
        patientIDs[patientIDNumber].push(counter);
        MedHxs[MedHx].push(counter);
        database[counter] = PatientDataStruct(name, grading, patientIDNumber, age_score, MedHx,  counter, who);
       
        counter++;
    }
 function retrieveRecord(
        string memory variant,
        string memory patientID,
        string memory drug
    ) public view returns (ObservationReturnStruct[] memory) {
        
        uint numFields;
        FieldQueries memory queryInfo;
        ObservationReturnStruct[] memory empty;
        uint[] memory variantSearch;
        uint[] memory patientIDSearch;
        uint[] memory MedHxSearch;
        uint[] memory indexSearch = new uint[](counter);
        UniqueObservations[] memory uniqueSearch = new UniqueObservations[](uniqueObservationsArray.length);

       
        if (counter == 0) {
            return empty;
        }
        
        if (compareStrings(variant, "*") == false) { // if variant field was not "*", increase numFields & mark variant true in queryInfo struct
            variantSearch = variants[stringToBytes32(variant)];
            numFields++;
            queryInfo.variantID = true;
        }
        if (compareStrings(patientID, "*") == false) { // if patientID field was not "*", increase numFields & mark patientID true in queryInfo struct
            patientIDSearch = patientIDs[stringToBytes32(patientID)];
            numFields++;
            queryInfo.patientIDNumber = true;
        }
        if (compareStrings(drug, "*") == false) { // if drug field was not "*", increase numFields & mark drug true in queryInfo struct
            MedHxSearch = MedHxs[drug];
            numFields++;
            queryInfo.drug = true;
        }

        uint matchCount; 
        uint uniqueCount; 

        if ((compareStrings(variant, "*") == true) &&
            (compareStrings(patientID, "*") == true) &&
            (compareStrings(drug, "*") == true)
            ) {
            matchCount = counter;
            uniqueCount = uniqueObservationsArray.length;
            uniqueSearch = uniqueObservationsArray;
            for (uint i; i < counter; i++) {
                indexSearch[i] = i;
            }
        } else {
            uint min = counter;
            uint which_one = 3;
            if (variantSearch.length <= min && variantSearch.length != 0){
                min = variantSearch.length;
                which_one = 0;
            }
            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
                min = patientIDSearch.length;
                which_one = 1;
            }
            if (MedHxSearch.length <= min && MedHxSearch.length != 0){
                min = MedHxSearch.length;
                which_one = 2;
            }
            if (variantSearch.length == patientIDSearch.length && patientIDSearch.length == MedHxSearch.length) {
                min = variantSearch.length;
                which_one = 0;
            }

            for (uint i; i < min; i++) {
                uint found = 1;
                
                if (which_one == 0) {
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (variantSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < MedHxSearch.length; j++){
                            if (variantSearch[i] == MedHxSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = variantSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[variantSearch[i]];
                        if (observationExistsUnique(addMe.variantField, addMe.patientIDField, addMe.MedHxField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.variantField, addMe.patientIDField, addMe.MedHxField);
                            uniqueCount++;
                        }
                    }
                }
                //if shortest array patientIDsearch
                if (which_one == 1){
                    if (queryInfo.variantID == true) {
                        for (uint j; j < variantSearch.length; j++){
                            if (patientIDSearch[i] == variantSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < MedHxSearch.length; j++){
                            if (patientIDSearch[i] == MedHxSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = patientIDSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[patientIDSearch[i]];
                        if (observationExistsUnique(addMe.variantField, addMe.patientIDField, addMe.MedHxField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.variantField, addMe.patientIDField, addMe.MedHxField);
                            uniqueCount++;
                        }
                    }
                }
                //if shortest array is MedHxsearch
                if (which_one == 2){
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (MedHxSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.variantID == true) {
                        for (uint j; j < variantSearch.length; j++){
                            if (MedHxSearch[i] == variantSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = MedHxSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[MedHxSearch[i]];
                        if (observationExistsUnique(addMe.variantField, addMe.patientIDField, addMe.MedHxField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.variantField, addMe.patientIDField, addMe.MedHxField);
                            uniqueCount++;
                        }
                    }
                }
            }
        }

        
        uint[] memory trimIndexSearch = new uint[](matchCount);
        UniqueObservations[] memory trimUniqueSearch = new UniqueObservations[](uniqueCount);
        for (uint i; i < matchCount; i++) {
            trimIndexSearch[i] = indexSearch[i];
        }
        for (uint j; j < uniqueCount; j++) {
            trimUniqueSearch[j] = uniqueSearch[j];
        }

       
        ObservationReturnStruct[] memory matches = new ObservationReturnStruct[](uniqueCount); // final struct array
        uint tally; // num entries for a given variantID-patientIDNumber-drug combo
        for (uint a; a < trimUniqueSearch.length; a++){
            uint[] memory sameThing = new uint[](counter);
            tally = 0;
            for (uint b; b < matchCount; b++) {
                 
                if ((trimUniqueSearch[a].variant == database[trimIndexSearch[b]].variantField) &&
                    (trimUniqueSearch[a].patientID == database[trimIndexSearch[b]].patientIDField) &&
                    compareStrings(trimUniqueSearch[a].MedHx, database[trimIndexSearch[b]].MedHxField)
                    ) {
                    sameThing[tally] = trimIndexSearch[b]; // add search result to sameThing if it matches uniqueSearch a
                    tally++;
                }
            }

            matches[a].variant = bytes32toString(database[sameThing[0]].variantField);
            matches[a].patientID = stringToInt(bytes32toString(database[sameThing[0]].patientIDField));
            matches[a].age = stringToInt(bytes32toString(database[sameThing[0]].ageField));
            matches[a].MedHx = database[sameThing[0]].MedHxField;
            matches[a].grade = stringToInt(bytes32toString(database[sameThing[0]].gradeField));
        }
        return matches; 
    }


   function observationExists(
        string memory variant,
        string memory patientID,
        string memory drug
    ) public view returns (bool){
         // initialize memory structs and variables
        uint numFields;
        uint[] memory variantSearch;
        uint[] memory patientIDSearch;
        uint[] memory MedHxSearch;

        FieldQueries memory queryInfo;
        if (counter == 0) {
            return false;
        }
        if (compareStrings(variant, "*") == false) {
            numFields++;
            queryInfo.variantID = true;
            variantSearch = variants[stringToBytes32(variant)];
        }
        if (compareStrings(patientID, "*") == false) {
            numFields++;
            queryInfo.patientIDNumber = true;
            patientIDSearch = patientIDs[stringToBytes32(patientID)];
        }
        if (compareStrings(drug, "*") == false) {
            numFields++;
            queryInfo.drug = true;
            MedHxSearch = MedHxs[drug];
        }

        if ((compareStrings(variant, "*") == true) &&
            (compareStrings(patientID, "*") == true) &&
            (compareStrings(drug, "*") == true)
            ) {
            return true;

        } else {
            uint min = counter;
            uint which_one = 3;
            if (variantSearch.length <= min && variantSearch.length != 0){
                min = variantSearch.length;
                which_one = 0;
            }
            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
                min = patientIDSearch.length;
                which_one = 1;
            }
            if (MedHxSearch.length <= min && MedHxSearch.length != 0){
                min = MedHxSearch.length;
                which_one = 2;
            }
            if (variantSearch.length == patientIDSearch.length && patientIDSearch.length == MedHxSearch.length) {
                min = variantSearch.length;
                which_one = 0;
            }
            uint found;
            for (uint i; i < min; i++) {
                found = 1;
                //if shortest array is variantsearch
                if (which_one == 0) {
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (variantSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < MedHxSearch.length; j++){
                            if (variantSearch[i] == MedHxSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields) {
                        break;
                    }
                }
                //if shortest array patientIDsearch
                if (which_one == 1){
                    if (queryInfo.variantID == true) {
                        for (uint j; j < variantSearch.length; j++){
                            if (patientIDSearch[i] == variantSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < MedHxSearch.length; j++){
                            if (patientIDSearch[i] == MedHxSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        break;
                    }
                }
                //if shortest array is MedHxsearch
                if (which_one == 2){
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (MedHxSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.variantID == true) {
                        for (uint j; j < variantSearch.length; j++){
                            if (MedHxSearch[i] == variantSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        break;
                    }
                }
            }
            if (found == numFields){
                return true;
            }
            else{
                return false;
            }
        }
    }

// Checks if a variantID-patientIDNumber-drug combination already exists in a UniqueObservations[] array and returns boolean
    function observationExistsUnique (
        bytes32 variant,
        bytes32 patientID,
        string memory drug,
        UniqueObservations[] memory array) internal pure returns (bool){
        if (array.length == 0) {
            return false;
        }
        uint searcher;
        for (uint j; j < array.length; j++) {
            if (array[j].variant == variant && array[j].patientID == patientID && compareStrings(array[j].MedHx, drug) == true) {
                searcher++;
                break;
            }
        }
        if (searcher == 1){
            return true;
        } else {
            return false;
        }
    }

// Converts uints to strings. from https://github.com/willitscale/solidity-util/blob/master/lib/Integers.sol
    function intToString(uint _base) internal pure returns (string memory) {
        bytes memory _tmp = new bytes(32);
        uint i;
        for(i; _base > 0; i++) {
            _tmp[i] = byte(uint8((_base % 10) + 48));
            _base /= 10;
        }
        bytes memory _real = new bytes(i--);
        for(uint j; j < _real.length; j++) {
            _real[j] = _tmp[i--];
        }
        return string(_real);
    }
    function stringToInt(string memory _value) internal pure returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }
    function compareStrings(
    	string memory a,
    	string memory b
    	) internal pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
  	function stringToBytes32(string memory _string) internal pure returns (bytes32) {
   		bytes32 _stringBytes;
    	assembly {
      	_stringBytes := mload(add(_string, 32))
    	}
    	return _stringBytes;
  	}
	function bytes32toString(bytes32 _data) internal pure returns (string memory) {
    	bytes memory _bytesContainer = new bytes(32);
    	uint256 _charCount;
    	for (uint256 _bytesCounter; _bytesCounter < 32; _bytesCounter++) {
      		bytes1 _char = bytes1(bytes32(uint256(_data) * 2 ** (8 * _bytesCounter)));
      		if (_char != 0) {
        		_bytesContainer[_charCount] = _char;
       			_charCount++;
      		}
    	}
    	bytes memory _bytesContainerTrimmed = new bytes(_charCount);
    	for (uint256 _charCounter; _charCounter < _charCount; _charCounter++) {
      		_bytesContainerTrimmed[_charCounter] = _bytesContainer[_charCounter];
    	}
    	return string(_bytesContainerTrimmed);
 	}

} 
