String captilizeInitial(String input){
    input = input.replaceAll("  ", " ");
    List<String> _names =  input.split(" ") ;
    for (int i =0; i <_names.length ; i++){
      try{
        _names[i] =  _names[i].trim();
       _names[i] =  _names[i][0].toUpperCase() +_names[i].substring(1);
      }catch(e){
        _names.removeAt(i);
      }
    }
    input = _names[0];
    for (int i = 1 ; i < _names.length; i++ ){
      input = input +  " " + _names[i]; 
    }

    return input ;
   
}