// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <=0.9.0;

contract BlocHealth {

    enum AccessRoles { Doctor, Staff, Nurse, Admins }
    enum EmergencyContactRoles { Mother, Father, Spouse, Child, Friend }

    struct Hospital {
        string name;
        string location;
        address owner;
        mapping (address => string) roles;
        mapping (address => Patient) patients;
    }

    struct Patient {
        string name;
        uint256 DOB;
        string gender;
        string[] allergies;
        string[] contactInformation;
        mapping (uint256 => Visit) visits;
        mapping (string => string) emergencyContacts;
        string[] insuranceDetails;
    }

    struct Visit {
        string[] currentMedications;
        string[] diagnosis;
        string[] treatmentPlan;
    }

    mapping (string => Hospital) public hospitals;
    address public owner;

    event HospitalCreated (string name, string hospitalId, address owner);
    event HospitalStaffRoleUpdated (string hospitalId, address _address, string role);
    event PatientCreated (string name, address patient, uint256 DOB);
    event VisitRecordCreated (string name, address patient, uint256 date);

    error IsNotValidAddressError (address _address);
    error HospitalDoesNotExistError (string hospitalId);
    error InvalidRoleError (string role);
    error NotHospitalOwnerError(address sender);
    error HospitalStaffDoesNotExistsError(address _address);
    error NotAuthorizedForHospitalError(address sender);
    error PatientDoesNotExistsError(address patient);

    constructor() {
        owner = msg.sender;
    }

    modifier isValidAddress (address _address) {
        if (_address == address(0)) {
            revert IsNotValidAddressError({ _address: _address });
        }
        _;
    }

    modifier hospitalExists (string memory _hospitalId) {
        if(hospitals[_hospitalId].owner == address(0)) {
            revert HospitalDoesNotExistError({ hospitalId: _hospitalId });
        }
        _;
    }

    modifier isValidRole (string memory _role) {
        if (keccak256(abi.encodePacked(_role)) != keccak256(abi.encodePacked(AccessRoles.Admins)) && keccak256(abi.encodePacked(_role)) != keccak256(abi.encodePacked(AccessRoles.Doctor)) && keccak256(abi.encodePacked(_role)) != keccak256(abi.encodePacked(AccessRoles.Nurse)) && keccak256(abi.encodePacked(_role)) != keccak256(abi.encodePacked(AccessRoles.Staff))) {
            revert InvalidRoleError({ role: _role });
        }
        _;
    }

    modifier onlyHospitalOwner (string memory _hospitalId) {
        if (msg.sender != hospitals[_hospitalId].owner) {
            revert NotHospitalOwnerError({ sender: msg.sender });
        }
        _;
    }

    modifier hospitalStaffExists (string memory _hospitalId, address _address) {
        Hospital storage hospital = hospitals[_hospitalId];
        if (keccak256(abi.encodePacked(hospital.roles[_address])) != keccak256(abi.encodePacked(AccessRoles.Admins)) || keccak256(abi.encodePacked(hospital.roles[_address])) != keccak256(abi.encodePacked(AccessRoles.Doctor)) || keccak256(abi.encodePacked(hospital.roles[_address])) != keccak256(abi.encodePacked(AccessRoles.Nurse)) || keccak256(abi.encodePacked(hospital.roles[_address])) != keccak256(abi.encodePacked(AccessRoles.Staff))) {
            revert HospitalStaffDoesNotExistsError({ _address: _address });
        }
        _;
    }

    modifier patientExists (string memory _hospitalId, address _patient) {
        Hospital storage hospital = hospitals[_hospitalId];
        if (keccak256(abi.encodePacked(hospital.patients[_patient].name)) == keccak256(abi.encodePacked("name"))) {
            revert PatientDoesNotExistsError({ patient: _patient });
        }
        _;
    }

    modifier isAuthorizedRole (string memory _hospitalId) {
        Hospital storage hospital = hospitals[_hospitalId];
        if (msg.sender != hospitals[_hospitalId].owner || keccak256(abi.encodePacked(hospital.roles[msg.sender])) != keccak256(abi.encodePacked(AccessRoles.Admins)) || keccak256(abi.encodePacked(hospital.roles[msg.sender])) != keccak256(abi.encodePacked(AccessRoles.Doctor)) || keccak256(abi.encodePacked(hospital.roles[msg.sender])) != keccak256(abi.encodePacked(AccessRoles.Nurse)) ) {
            revert NotAuthorizedForHospitalError({ sender: msg.sender });
        }
        _;
    }

    function addHospital (string memory _hospitalId, string memory _name, string memory _location) external {
        Hospital storage hospital = hospitals[_hospitalId];
        hospital.name = _name;
        hospital.location = _location;
        hospital.owner = msg.sender;

        emit HospitalCreated(_name, _hospitalId, msg.sender);
    }

    function updateHospitalStaffRoles (string memory _hospitalId, address _address, string memory _role) onlyHospitalOwner(_hospitalId) isValidAddress(_address) hospitalExists(_hospitalId) isValidRole(_role) external {
        Hospital storage hospital = hospitals[_hospitalId];
        hospital.roles[_address] = _role;

        emit HospitalStaffRoleUpdated(_hospitalId, _address, _role);
    }

    function deleteHospital (string memory _hospitalId) onlyHospitalOwner(_hospitalId) hospitalExists(_hospitalId) external {
        delete hospitals[_hospitalId];
    }

    function deleteHospitalStaff (string memory _hospitalId, address _address) onlyHospitalOwner(_hospitalId) hospitalExists(_hospitalId) isValidAddress(_address) hospitalStaffExists(_hospitalId, _address) external {
        delete hospitals[_hospitalId].roles[_address];
    }

    function createPatientRecord (string memory _hospitalId, address _patient, string memory _name, uint256 _DOB, string[] calldata _allergies, string[] calldata _contactInformation, string[] calldata _insuranceDetails) isAuthorizedRole(_hospitalId) isValidAddress(_patient) external {
        Patient storage patient = hospitals[_hospitalId].patients[_patient];
        patient.name = _name;
        patient.DOB = _DOB;
        
        for (uint iA = 0; iA < _allergies.length; iA++) {
            patient.allergies.push(_allergies[iA]);
        }

        for (uint iC = 0; iC < _contactInformation.length; iC++) {
            patient.contactInformation.push(_contactInformation[iC]);
        }

        for (uint iI = 0; iI < _insuranceDetails.length; iI++) {
            patient.insuranceDetails.push(_insuranceDetails[iI]);
        }

        emit PatientCreated(_name, _patient, _DOB);
    }

    function deletePatientRecord (string memory _hospitalId, address _patient) isAuthorizedRole(_hospitalId) patientExists(_hospitalId, _patient) external {
        delete hospitals[_hospitalId].patients[_patient];
    }

    function uploadVisitRecord (string memory _hospitalId, address _patient, uint256 _date, string[] calldata _currentMedications, string[] calldata _diagnosis, string[] calldata _treatmentPlan) isAuthorizedRole(_hospitalId) patientExists(_hospitalId, _patient) external {
        Patient storage patient = hospitals[_hospitalId].patients[_patient];

        for (uint iC = 0; iC < _currentMedications.length; iC++) {
            patient.visits[_date].currentMedications.push(_currentMedications[iC]);
        }

        for (uint iD = 0; iD < _diagnosis.length; iD++) {
            patient.visits[_date].diagnosis.push(_diagnosis[iD]);
        }

        for (uint iT = 0; iT < _treatmentPlan.length; iT++) {
            patient.visits[_date].treatmentPlan.push(_treatmentPlan[iT]);
        }

        emit VisitRecordCreated(patient.name, _patient, _date);
    }
}