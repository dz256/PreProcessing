function interpData = interpolateStriatum(oldTAxis, ydata, newTAxis)
   interpData = interp1(oldTAxis,ydata,newTAxis,'pchip');

end