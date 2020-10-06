// Copyright (c) Ivan Bondarev, Stanislav Mikhalkovich (for details please see \doc\copyright.txt)
// This code is distributed under the GNU LGPL (for details please see \doc\license.txt)

uses FilesOperations, System.IO, System.Resources;

begin
  var res: string;
  var Files := DirectoryInfo.Create('..\..\bin\lng\rus').GetFiles('*.*');
  Writeln($'Found {Files.Length} files, processing...');
  
  foreach var f in Files do
    res += 2 * NewLine + '//' + f.Name + NewLine + '%PREFIX%=' + NewLine + ReadFileToEnd(f.FullName);
  
  Writeln('Saving generated file as resource...');
  var ResWriter := ResourceWriter.Create('..\..\Localization\DefaultLang.resources');
  ResWriter.AddResource('DefaultLanguage', System.Text.Encoding.GetEncoding(1251).GetBytes(res));
  ResWriter.Generate;
  ResWriter.Close;
  Writeln('OK');
end.
