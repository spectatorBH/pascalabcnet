﻿unit SF;

procedure Pr(params a: array of object) := Print(a);
procedure Pr(o: object) := Print(o);
procedure Pr(s: string) := Print(s);
procedure Prln(params a: array of object) := Println(a);

function RI := ReadInteger;
function RI64 := ReadInt64;
function RR := ReadReal;
function RC := ReadChar;
function RS := ReadString;

function RlnI := ReadlnInteger;
function RlnI64 := ReadlnInt64;
function RlnR := ReadlnReal;
function RlnC := ReadlnChar;
function RlnS := ReadlnString;

function RI2 := ReadInteger2;
function RR2 := ReadReal2;
function RC2 := ReadChar2;
function RS2 := ReadString2;

function RlnI2 := ReadlnInteger2;
function RlnR2 := ReadlnReal2;
function RlnC2 := ReadlnChar2;
function RlnS2 := ReadlnString2;

function RI3 := ReadInteger3;
function RR3 := ReadReal3;
function RC3 := ReadChar3;
function RS3 := ReadString3;

function RlnI3 := ReadInteger3;
function RlnR3 := ReadlnReal3;
function RlnC3 := ReadlnChar3;
function RlnS3 := ReadlnString3;



end.