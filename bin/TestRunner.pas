// This code is distributed under the GNU LGPL (for details please see \doc\license.txt)
{$reference Compiler.dll}
{$reference CodeCompletion.dll}
{$reference Errors.dll}
{$reference CompilerTools.dll}
{$reference Localization.dll}
{$reference System.Windows.Forms.dll}

uses
  PascalABCCompiler,
  System.IO,
  System.Diagnostics;

var
  StartTime    : integer;
  TestSuiteDir : string;
  PathSeparator: string := Path.DirectorySeparatorChar;

function IsUnix: boolean;
begin
  Result := (System.Environment.OSVersion.Platform = System.PlatformID.Unix) or (System.Environment.OSVersion.Platform = System.PlatformID.MacOSX);
end;

function GetTestSuiteDir: string;
begin
  var dir := Path.GetDirectoryName(GetEXEFileName());
  var ind := dir.LastIndexOf('bin');
  Result := dir.Substring(0, ind) + 'TestSuite';
end;

function GetLibDir: string;
begin
  var dir := Path.GetDirectoryName(GetEXEFileName());
  Result := dir + PathSeparator + 'Lib';
end;

procedure CompileErrorTests(withide: boolean);
begin
  
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'errors', '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    
    var co: CompilerOptions := new CompilerOptions(files[i], CompilerOptions.OutputType.ConsoleApplicaton);
    co.Debug := true;
    co.OutputDirectory := TestSuiteDir + PathSeparator + 'errors';
    co.UseDllForSystemUnits := false;
    co.RunWithEnvironment := withide;
    comp.ErrorsList.Clear();
    comp.Warnings.Clear();
    
    comp.Compile(co);
    if comp.ErrorsList.Count = 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Compilation of error sample ' + files[i] + ' was successfull' + System.Environment.NewLine);
      Console.Error.WriteLine(NewLine + '***ERROR: Compilation of ERROR sample ' + files[i] + ' was successfull -- This is WRONG and not expected!' + NewLine);
      Halt(1);
    end
    else if comp.ErrorsList.Count = 1 then
    begin
      if comp.ErrorsList[0].GetType() = typeof(PascalABCCompiler.Errors.CompilerInternalError) then
        //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
        Writeln(NewLine + 'Compilation of ERROR sample ' + files[i] + ' failed as expected' + NewLine + comp.ErrorsList[0].ToString());
    end;
    if i mod 50 = 0 then
      System.GC.Collect();
  end;
  
end;

procedure CompileAllRunTests(withdll: boolean; only32bit: boolean := false);
begin
  
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir, '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    if content.StartsWith('//nopabcrtl') and withdll then
      continue;
    var co: CompilerOptions := new CompilerOptions(files[i], CompilerOptions.OutputType.ConsoleApplicaton);
    co.Debug := true;
    co.OutputDirectory := TestSuiteDir + PathSeparator + 'exe';
    co.UseDllForSystemUnits := withdll;
    co.RunWithEnvironment := false;
    co.IgnoreRtlErrors := false;
    co.Only32Bit := only32bit;
    comp.ErrorsList.Clear();
    comp.Warnings.Clear();
    
    comp.Compile(co);
    if comp.ErrorsList.Count > 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
      Console.Error.WriteLine(NewLine + '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString());
      Halt(1);
    end;
    if i mod 50 = 0 then
    begin
      System.GC.Collect();
    end;  
  end;
  //Println;
end;

procedure CompileAllCompilationTests(dir: string; withdll: boolean);
begin
  
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + dir, '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    var co: CompilerOptions := new CompilerOptions(files[i], CompilerOptions.OutputType.ConsoleApplicaton);
    co.Debug := true;
    co.OutputDirectory := TestSuiteDir + PathSeparator + dir;
    co.UseDllForSystemUnits := withdll;
    co.RunWithEnvironment := false;
    co.IgnoreRtlErrors := false;
    comp.ErrorsList.Clear();
    comp.Warnings.Clear();
    
    comp.Compile(co);
    if comp.ErrorsList.Count > 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
      Console.Error.WriteLine(NewLine + '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString());
      Halt(1);
    end;
    if i mod 50 = 0 then
      System.GC.Collect();
  end;
  
end;

procedure CompileAllUnits;
begin
  var comp := new Compiler();
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'units', '*.pas');
  var dir := TestSuiteDir + PathSeparator + 'units' + PathSeparator;
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    var co: CompilerOptions := new CompilerOptions(files[i], CompilerOptions.OutputType.ConsoleApplicaton);
    co.Debug := true;
    co.OutputDirectory := dir;
    co.UseDllForSystemUnits := false;
    comp.ErrorsList.Clear();
    comp.Warnings.Clear();
    
    comp.Compile(co);
    if comp.ErrorsList.Count > 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
      Console.Error.WriteLine(NewLine + '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString());
      Halt(1);
    end;
  end;
  System.GC.Collect;
end;

procedure CompileAllUsesUnits;
begin
  System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'usesunits', '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    var co: CompilerOptions := new CompilerOptions(files[i], CompilerOptions.OutputType.ConsoleApplicaton);
    co.Debug := true;
    co.OutputDirectory := TestSuiteDir + PathSeparator + 'exe';
    co.UseDllForSystemUnits := false;
    comp.ErrorsList.Clear();
    comp.Warnings.Clear();
    comp.Compile(co);
    if comp.ErrorsList.Count > 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
      Console.Error.WriteLine(NewLine + '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString());
      Halt(1);
    end;
  end;
  System.GC.Collect;
end;

procedure CopyPCUFiles;
begin
  System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'units', '*.pcu');
  
  foreach fname: string in files do
  begin
    &File.Move(fname, TestSuiteDir + PathSeparator + 'usesunits' + PathSeparator + Path.GetFileName(fname));
  end;
end;

procedure RunAllTests(redirectIO: boolean);
begin
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'exe', '*.exe');
  for var i := 0 to files.Length - 1 do
  begin
    //Println(files[i]);
    var psi := new System.Diagnostics.ProcessStartInfo(files[i]);
    psi.CreateNoWindow := true;
    psi.UseShellExecute := false;
    
    psi.WorkingDirectory := TestSuiteDir + PathSeparator + 'exe';
		  {psi.RedirectStandardInput := true;
		  psi.RedirectStandardOutput := true;
		  psi.RedirectStandardError := true;}
    var p: Process := new Process();
    p.StartInfo := psi;
    p.Start();
    if redirectIO then
      p.StandardInput.WriteLine('GO');
		  //p.StandardInput.AutoFlush := true;
		  //var p := System.Diagnostics.Process.Start(psi);
    
    while not p.HasExited do
      Sleep(10);
    if p.ExitCode <> 0 then
    begin
      //System.Windows.Forms.MessageBox.Show('Running of ' + files[i] + ' failed. Exit code is not 0');
      Console.Error.WriteLine(NewLine + $'***ERROR: Running of ' + files[i] + ' failed -- Exit code is not 0 ({p.ExitCode})' + NewLine);
      Halt(p.ExitCode);
    end;
  end;
end;

procedure RunExpressionsExtractTests;
begin
  CodeCompletion.CodeCompletionTester.Test();  
end;

function GetLineByPos(lines: array of string; pos: integer): integer;
begin
  var cum_pos := 0;
  for var i := 0 to lines.Length - 1 do
    for var j := 0 to lines[j].Length - 1 do
    begin
      if cum_pos = pos then
      begin
        Result := i + 1;
        exit;
      end;
      Inc(cum_pos);  
    end;
end;

function GetColByPos(lines: array of string; pos: integer): integer;
begin
  var cum_pos := 0;
  for var i := 0 to lines.Length - 1 do
    for var j := 0 to lines[j].Length - 1 do
    begin
      if cum_pos = pos then
      begin
        Result := j + 1;
        exit;
      end;
      Inc(cum_pos);  
    end;
end;

procedure RunIntellisenseTests;
begin
  PascalABCCompiler.StringResourcesLanguage.CurrentTwoLetterISO := 'ru';
  CodeCompletion.CodeCompletionTester.TestIntellisense(TestSuiteDir + PathSeparator + 'intellisense_tests');
end;

procedure RunFormatterTests;
begin
  CodeCompletion.FormatterTester.Test();
  var errors := &File.ReadAllText(TestSuiteDir + PathSeparator + 'formatter_tests' + PathSeparator + 'output' + PathSeparator + 'log.txt');
  if not string.IsNullOrEmpty(errors) then
  begin
    //System.Windows.Forms.MessageBox.Show(errors + System.Environment.NewLine + 'more info at TestSuite/formatter_tests/output/log.txt');
    Console.Error.WriteLine(NewLine + '***ERROR: check TestSuite/formatter_tests/output/log.txt:' + NewLine + errors);
    Halt(1);
  end;
end;

procedure ClearDirByPattern(dir, pattern: string);
begin
  var files := Directory.GetFiles(dir, pattern);
  for var i := 0 to files.Length - 1 do
  begin
    try
      if Path.GetFileName(files[i]) <> '.gitignore' then
        &File.Delete(files[i]);
    except
    end;
  end;
end;

procedure ClearExeDir;
begin
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'exe', '*.*');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'CompilationSamples', '*.exe');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'CompilationSamples', '*.mdb');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'CompilationSamples', '*.pdb');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'CompilationSamples', '*.pcu');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'pabcrtl_tests', '*.exe');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'pabcrtl_tests', '*.pdb');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'pabcrtl_tests', '*.mdb');
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'pabcrtl_tests', '*.pcu');
end;

procedure DeletePCUFiles;
begin
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'usesunits', '*.pcu');
end;

procedure DeletePABCSystemPCU;
begin
  var dir := Path.Combine(Path.GetDirectoryName(GetEXEFileName()), 'Lib');
  var pcu := Path.Combine(dir, 'PABCSystem.pcu');
end;

procedure CopyLibFiles(TestSubDir: string);
begin
  var files := Directory.GetFiles(GetLibDir(), '*.pas');
  foreach f: string in files do
  begin
    &File.Copy(f, Path.Combine(TestSuiteDir, TestSubDir, Path.GetFileName(f)), true);
  end;
end;

function ToMinSec(self: integer): string; extensionmethod := $'{(self div 60000)}m:{(self div 1000 mod 60):00}s';

procedure WriteStep(str1: string; str2: string := '');
const
  RightMargin = 47;
  LeftPadding = 5;
begin
  if str2 = '' then
    writeln(str1)
  else
    write((LeftPadding * ' ' + str1).PadRight(RightMargin) + str2);
end;

begin
  //DeletePABCSystemPCU;
  if ParamCount = 0 then 
  begin
    writeln;
    writeln('[Compilation, unit and functional tests -- FULL SET] >>>>>>>>>>>> START');
    StartTime := Milliseconds;
  end
  else if ((ParamStr(1).Length > 1)) or not (ParamStr(1)[1] in ['1'..'5']) then 
  begin
    writeln;
    writeln($'***Error*** Test group "{ParamStr(1)}" not recognized as valid');
    writeln;
    writeln('  USAGE: TestRunner [group_N], where group_N = 1..5');
    writeln;
    writeln('  Launching without any arguments would run FULL SET of tests (5 groups) sequentially.');
    writeln;
    Halt
  end;
  
  try
    TestSuiteDir := GetTestSuiteDir;
    System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
    
    if (ParamCount = 0) or (ParamStr(1) = '1') then
    begin
      writeln;
      writeln('-----------------------------------------------------------------------');
      writeln('  [Group 1/5] Generic unit tests in default mode (64-bit preferred):   ');
      writeln('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDir;
      WriteStep('a) Compilation step', '-> ');
      CompileAllRunTests(false);
      WriteStep('PASSED');
      WriteStep('b) Run step', '-> ');
      RunAllTests(false);
      WriteStep('PASSED');
      ClearExeDir;
      writeln('________________________');
      writeln($'Elapsed time = {MillisecondsDelta.ToMinSec}');
    end;
    
    if (ParamCount = 0) or (ParamStr(1) = '2') then
    begin
      writeln;
      writeln('-----------------------------------------------------------------------');
      writeln('  [Group 2/5] Generic unit tests in 32bit mode (forced):               ');
      writeln('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDir;
      WriteStep('a) Compilation step', '-> ');
      CompileAllRunTests(false, true);        
      WriteStep('PASSED');
      WriteStep('b) Run step', '-> ');
      RunAllTests(false);
      WriteStep('PASSED');
      ClearExeDir;
      writeln('________________________');
      writeln($'Elapsed time = {MillisecondsDelta.ToMinSec}');
    end;
    
    if (ParamCount = 0) or (ParamStr(1) = '3') then
    begin
      writeln;
      writeln('-----------------------------------------------------------------------');
      writeln('  [Group 3/5] Custom unit tests with PABCRtl.dll (64-bit preferred):   ');
      writeln('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDir;
      WriteStep('a) Compilation step (generic samples)', '-> ');
      CompileAllRunTests(true);
      WriteStep('PASSED');
      WriteStep('b) Compilation step (special samples)', '-> ');
      CompileAllCompilationTests('pabcrtl_tests', true);
      WriteStep('PASSED');
      WriteStep('c) Run step (all samples)', '-> ');
      RunAllTests(false);
      WriteStep('PASSED');
      ClearExeDir;
      writeln('________________________');
      writeln($'Elapsed time = {MillisecondsDelta.ToMinSec}');
    end;
    
    if (ParamCount = 0) or (ParamStr(1) = '4') then
    begin
      writeln;
      writeln('-----------------------------------------------------------------------');
      writeln('  [Group 4/5] Compilation tests of precrafted code samples:            ');
      writeln('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDir;
      WriteStep('a) ERROR-FREE samples', '-> ');
      CopyLibFiles('CompilationSamples');
      CompileAllCompilationTests('CompilationSamples', false);
      WriteStep('PASSED');
      WriteStep('b) ERROR samples ', '-> ');
      CompileAllUnits;
      CopyPCUFiles;
      CompileAllUsesUnits;
      CompileErrorTests(false);
      WriteStep('PASSED //by failure, as expected');
      //WriteStep('c) DEMO (bundled) samples', '-> ');
      //WriteStep('N/A    //not implemented yet');
      ClearExeDir;
      writeln('________________________');
      writeln($'Elapsed time = {MillisecondsDelta.ToMinSec}');
    end;
    
    if (ParamCount = 0) or (ParamStr(1) = '5') then
    begin
      writeln;
      writeln('-----------------------------------------------------------------------');
      writeln('  [Group 5/5] IDE internals tests:                                     ');
      writeln('-----------------------------------------------------------------------');
      System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
      WriteStep('a) Intellisense (expressions)', '-> ');
      RunExpressionsExtractTests;
      WriteStep('PASSED');
      //WriteStep('b) Intellisense (other)', '-> ');
      //RunIntellisenseTests;
      //WriteStep('PASSED');
      WriteStep('c) Code Formatter', '-> ');
      CopyLibFiles('formatter_tests\input');
      RunFormatterTests;
      WriteStep('PASSED');
      writeln('________________________');
      writeln($'Elapsed time = {MillisecondsDelta.ToMinSec}');
      
    end;
  except
    on e: Exception do
      //assert(false, e.ToString());
      Console.Error.WriteLine(NewLine + $'***ERROR: {e.ToString()}');
      Halt(1)
  end;
  if ParamCount = 0 then
  begin
    writeln;
    writeln('________________________________');
    writeln($'  Total time = {(Milliseconds - StartTime).ToMinSec}');
    writeln;
    writeln('[Compilation, unit and functional tests] >>>>>>>>>>>>>>>>>>>>>>> FINISH');
  end;
  writeln;
end.
