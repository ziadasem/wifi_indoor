

import 'package:flutter/material.dart';

InputDecoration inputDecoration (label, IconData icons , {bool showPasswordIcon = false , Function? function}){
    return InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Color(0xff8C8FA5) , ),
                
                border: const OutlineInputBorder(
                        borderSide:BorderSide(color:  Color(0xffF3F4F8)) ,
                        borderRadius: BorderRadius.all(Radius.circular(10) )
                ),               
                filled: true,
                suffixIcon: showPasswordIcon
                      ?IconButton(icon: const Icon(Icons.visibility), onPressed: ()=> function)
                      :null,
          
                fillColor: Color(0xffF3F4F8),
                  prefixIcon: Icon(icons, color: Colors.grey,),
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              );
              
  }
  ButtonStyle buttonStyle(Color color) {
  return ButtonStyle(
    padding: MaterialStateProperty.resolveWith((states) => EdgeInsets.only(left: 40, right: 40, top: 15, bottom: 15)),
      backgroundColor: MaterialStateProperty.resolveWith((states) => color),
      shape: MaterialStateProperty.resolveWith((states) =>
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))));
}
