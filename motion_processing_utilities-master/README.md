# motion_processing_utilities
Scripts useful for processing motion-ball data given the setup up through 10-02-17

1. Navigate to directory with vrffile
2. load vrffile ('load('NAMEOFVRFFILE')')
3. type [data, info] = getData(vrffile);
4. To get motion data, type [A, b, c, d] = getMovement(data);
5. For further manipulations such as interpolation, etc., check out loadAndProcessPreInfusion2.m for example implementations.
6. To extract tiff timestamps, run getAllTimeStamps
7. motion timestamps should be in the info struct you get from getData. Make sure to subtract time point t=0
8. Use the tiff timestamps to interpolate fluorescence, movement timestamps to interpolate movement
9. Be careful with interpolating movement. It is an accumulator. Originally I just interpolated the dy's and dx's, which is approximately alright. I think a better approach would be to first divide by the measured dt and interpolate approximate velocities at each instant. That's what I intend to do for the second paper.
