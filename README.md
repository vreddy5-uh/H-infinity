Project name: Study on FPGA-based computation units for Ocular Artifact Removal filter algorithm for multi-channel Electroencephalography(EEG)

Creator: Reddy, Vishal Reddy 

Mentor : Contreras Vidal, Jose L

Lab name: IUCRC BRAIN

Date: 05/06/2024



Data files used for testing and validation:

	Input from MATLAB: EEG_data_HPF_input_float_from_MATLAB.csv
	Python script to convert to fixed point 64-bit (1,28,35) format: Python_script_for_fixed_point_conversion.ipynb

	Input data file to H-infinity module: EEG_data_HPF_input_64_bit_fixed.csv
	Output data file from H-infinity module: EEG_data_Hinf_Output_64_1_28_35_fixed.csv

	Output from python script after converting from 64-bit fixed point to float: EEG_data_Hinf_output_64_1_28_35_float.csv

	Reference output from MATLAB used for correlation: EEG_data_Hinf_HPF_output_from_MATLAB.csv

Design files:
	
	64-bit custom divide module: divide.v
	128-bit custom divide module: divide_128.v
	3x3 matrix inversion module: invert.v
	H-infinity top level module: Hinftop.v
	
	Testbench code: Hinftop_tb.v 
	
	Constraints file: constraints.xdc
	
Results from Thesis Report:

	Fig 5.14. shows Raw EEG data plot from MATLAB - EEG_data_raw.csv
	Fig 5.15. shows High pass filtered EEG data plot from MATLAB - EEG_data_HPF_input_float_from_MATLAB.csv
	Fig 5.16. Reference H-infinity filtered EEG data plot from MATLAB - EEG_data_Hinf_HPF_output_from_MATLAB.csv
	FIg 5.17. Final output H-infinity filtered EEG data from FPGA - EEG_data_Hinf_output_64_1_28_35_float.csv
