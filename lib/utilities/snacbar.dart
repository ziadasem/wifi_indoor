
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

void openSnacbar(_scaffoldKey, snacMessage){
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
    content: Container(
      alignment: Alignment.centerLeft,
      height: 60,
      child: Text(
        snacMessage,
        style: TextStyle(
          fontSize: 14,
        ),
      ),
    ),
    action: SnackBarAction(
      label: 'Ok',
      textColor: Colors.blueAccent,
      onPressed: () {},
    ),
  )
    );
  
  }


//sort length
void openToast(context, message, {isError = false}){
  ToastContext().init(context);
  Toast.show(message, textStyle:TextStyle( color:  isError ?Colors.red :Colors.white), backgroundRadius: 20, duration: Toast.lengthShort);
  }

//long length
void openToast1(context, message , {isError = false}){
  ToastContext().init(context);
  Toast.show(message, textStyle:TextStyle( color:  isError ?Colors.red :Colors.white), backgroundRadius: 20, duration: Toast.lengthLong);
  
  }