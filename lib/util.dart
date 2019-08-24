/// scales a number in a range to another range.
/// - How can this be made to work with any number of number types
/// TODO - make this use generics.
double scaleNum(num, inMin, inMax, outMin, outMax) {
  // return (num - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  return (num - inMin) / (inMax - inMin) * (outMax - outMin) + outMin;
}


// These are the same but, for clarity...

msToBpm(double ms) {
  return 60000 / ms;
}

bpmToMS(double bpm) {
  return  60000 / bpm;
}