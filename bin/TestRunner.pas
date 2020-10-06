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
  TestSuiteDir:  string;
  PathSeparator: string := Path.DirectorySeparatorChar;
  
{function GetLineByPos(lines: array of string; pos: integer): integer;
begin
  var cum_pos := 0;
  for var i := 0 to lines.Length - 1 do
    for var j := 0 to lines[i].Length - 1 do
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
    for var j := 0 to lines[i].Length - 1 do
    begin
      if cum_pos = pos then
      begin
        Result := j + 1;
        exit;
      end;
      Inc(cum_pos);  
    end;
end;}

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
  Log.WriteLine($'[ClearDirByPattern] Emptied all {pattern} in {dir}');
end;

procedure ClearExeDirs;
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

{procedure DeletePABCSystemPCU;
begin
  var dir := Path.Combine(Path.GetDirectoryName(GetEXEFileName()), 'Lib');
  var pcu := Path.Combine(dir, 'PABCSystem.pcu');
end;}

procedure DeletePCUFiles;
begin
  ClearDirByPattern(TestSuiteDir + PathSeparator + 'usesunits', '*.pcu');
end;

procedure CopyPCUFiles;
begin
  System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'units', '*.pcu');
  foreach fname: string in files do
  begin
    var fname_new := Path.Combine(TestSuiteDir, 'usesunits', Path.GetFileName(fname));
    &File.Move(fname, fname_new);
    Log.WriteLine($'[CopyPCUFiles] Moving: {fname} --> {fname_new}');
  end;
end;

procedure CopyLibFiles(TestSubDir: string);
begin
  var files := Directory.GetFiles(GetLibDir(), '*.pas');
  foreach fname: string in files do
  begin
    var fname_copy := Path.Combine(TestSuiteDir, TestSubDir, Path.GetFileName(fname));
    &File.Copy(fname, fname_copy, true);
    Log.WriteLine($'[CopyLibFiles] Copying: {fname} --> {fname_copy}');
  end;
end;

procedure CompileErrorTests(withide: boolean);
begin
  Log.WriteLine('[CompileErrorTests] -- Started:');
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'errors', '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    Log.WriteLine('Compiling...' + files[i]);
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
      var Message := '***ERROR: Compilation of ERROR sample ' + files[i] + ' was successfull -- This is WRONG now and not expected!';
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(1);
    end
    else if comp.ErrorsList.Count = 1 then
    begin
      if comp.ErrorsList[0].GetType() = typeof(PascalABCCompiler.Errors.CompilerInternalError) then
      begin
        //System.Windows.Forms.MessageBox.Show('Compilation of ' + files[i] + ' failed' + System.Environment.NewLine + comp.ErrorsList[0].ToString());
        var Message := '***ERROR: Internal compiler error with ' + files[i] + NewLine + comp.ErrorsList[0].ToString;
        Console.Error.WriteLine(NewLine + Message + NewLine);
        Log.WriteLine(Message);
        Log.Flush;
        Halt(1);
      end;
    end;
    if i mod 50 = 0 then
      System.GC.Collect();
  end;
  Log.WriteLine('[CompileErrorTests] -- Finished.');
end;

procedure CompileAllRunTests(withdll: boolean; only32bit: boolean := false);
begin
  Log.WriteLine($'[CompileAllRunTests] -- Started:');
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir, '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    if content.StartsWith('//nopabcrtl') and withdll then
      continue;
    Log.WriteLine('Compiling...' + files[i]);
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
      var Message := '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString;
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(1);
    end;
    if i mod 50 = 0 then
      System.GC.Collect();
  end;
  Log.WriteLine('[CompileAllRunTests] -- Finished.');
end;

procedure CompileAllCompilationTests(dir: string; withdll: boolean);
begin
  Log.WriteLine($'[CompileAllCompilationTests] -- Started:');
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + dir, '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    Log.WriteLine('Compiling...' + files[i]);
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
      var Message := '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString;
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(1);
    end;
    if i mod 50 = 0 then
      System.GC.Collect();
  end;
  Log.WriteLine($'[CompileAllCompilationTests] -- Finished.');
end;

procedure CompileAllUnits;
begin
  Log.WriteLine($'[CompileAllUnits] -- Started:');
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'units', '*.pas');
  var dir := TestSuiteDir + PathSeparator + 'units' + PathSeparator;
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    Log.WriteLine('Compiling...' + files[i]);
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
      var Message := '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString;
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(1);
    end;
  end;
  System.GC.Collect;
  Log.WriteLine($'[CompileAllUnits] -- Finished.');
end;

procedure CompileAllUsesUnits;
begin
  Log.WriteLine($'[CompileAllUsesUnits] -- Started:');
  System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
  var comp := new Compiler();
  
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'usesunits', '*.pas');
  for var i := 0 to files.Length - 1 do
  begin
    var content := &File.ReadAllText(files[i]);
    if content.StartsWith('//winonly') and IsUnix then
      continue;
    Log.WriteLine('Compiling...' + files[i]);
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
      var Message := '***ERROR: Compilation of ' + files[i] + ' failed' + NewLine + comp.ErrorsList[0].ToString;
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(1);
    end;
  end;
  System.GC.Collect;
  Log.WriteLine($'[CompileAllUsesUnits] -- Finished.');
end;

procedure RunAllTests(redirectIO: boolean);
begin
  Log.WriteLine($'[RunAllTests] -- Started:');
  var files := Directory.GetFiles(TestSuiteDir + PathSeparator + 'exe', '*.exe');
  for var i := 0 to files.Length - 1 do
  begin
    Log.WriteLine(files[i]);
    Log.WriteLine('Running...' + files[i]);
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
      var Message := $'***ERROR: Running of ' + files[i] + ' failed -- Exit code is not 0 ({p.ExitCode})';
      Console.Error.WriteLine(NewLine + Message + NewLine);
      Log.WriteLine(Message);
      Log.Flush;
      Halt(p.ExitCode);
    end;
  end;
  Log.WriteLine('[RunAllTests] -- Finished.');
end;

procedure RunExpressionsExtractTests;
begin
  Log.WriteLine('[RunExpressionsExtractTests] -- Started:');
  CodeCompletion.CodeCompletionTester.Test();
  Log.WriteLine('[RunExpressionsExtractTests] -- Finished.');
end;

procedure RunIntellisenseTests;
begin
  Log.WriteLine('[RunIntellisenseTests] -- Started:');
  PascalABCCompiler.StringResourcesLanguage.CurrentTwoLetterISO := 'ru';
  CodeCompletion.CodeCompletionTester.TestIntellisense(TestSuiteDir + PathSeparator + 'intellisense_tests');
  Log.WriteLine('[RunIntellisenseTests] -- Finished.');
end;

procedure RunFormatterTests;
begin
  Log.WriteLine('[RunFormatterTests] -- Started:');
  CodeCompletion.FormatterTester.Test();
  var errors := &File.ReadAllText(TestSuiteDir + PathSeparator + 'formatter_tests' + PathSeparator + 'output' + PathSeparator + 'log.txt');
  if not string.IsNullOrEmpty(errors) then
  begin
    //System.Windows.Forms.MessageBox.Show(errors + System.Environment.NewLine + 'more info at TestSuite/formatter_tests/output/log.txt');
    var Message := '***ERROR: Info from TestSuite/formatter_tests/output/log.txt:' + NewLine + errors;
    Console.Error.WriteLine(NewLine + Message + NewLine);
    Log.WriteLine(Message);
    Log.Flush;
    Halt(1);
  end;
  Log.WriteLine('[RunFormatterTests] -- Finished.');
end;

procedure write2(msg: string);
begin
  write(msg);
  Log.Write(msg);
end;

procedure writeln2(msg: string) := write2(msg + NewLine);

function StepTime: string := $'{System.Math.Round(MillisecondsDelta/1000, System.MidpointRounding.AwayFromZero)}s';

function ToMinSec(self: integer): string; extensionmethod := $'{(self div 60000)}m:{(self div 1000 mod 60):00}s';

procedure WriteStep(str1: string; str2: string := '');
const
  RightMargin = 47;
  LeftPadding = 5;
begin
  if str2 = '' then
    writeln2(str1)
  else
    write2((LeftPadding * ' ' + str1).PadRight(RightMargin) + str2);
end;

begin
  //DeletePABCSystemPCU;
  var ParamSet: set of string;
  for var i := 1 to ParamCount() do
  begin
    ParamSet += [ParamStr(i)];
    if (ParamStr(i).Length > 1) or not (ParamStr(i)[1] in ['1'..'5']) then
    begin
      Writeln;
      Writeln($'***Error: Option "{ParamStr(i)}" not recognized as valid test group No.');
      writeln;
      writeln('  USAGE: TestRunner [<groupN_list>] , where:');
      writeln;
      writeln('    <groupN_list> = list of space-separated numbers in range of [1..5],');
      writeln('                    defining the desired CUSTOM SET of tests to run.');
      writeln;
      writeln('  Examples: "TestRunner 5", "TestRunner 1 2 3"');
      writeln('  Launching without any options would run FULL SET (5 groups) of tests sequentially.');
      writeln;
      Halt(-1)
    end;
  end;
  
  var Log := new StreamWriter('TestRunner_verbose.log', false);
  Log.WriteLine(DateTime.Now.ToString + NewLine);
  System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
  TestSuiteDir := GetTestSuiteDir();
  writeln;
  if ParamCount = 0
  then
    writeln('[Compilation, unit and functional tests -- FULL SET] >>>>>>>>>>>> START')
  else 
    writeln('[Compilation, unit and functional tests -- CUSTOM SET] >>>>>>>>>> START');
  
  var StartTime := Milliseconds;
  var GroupTime: integer;
  try
    if (ParamCount = 0) or ('1' in ParamSet) then
    begin
      GroupTime := Milliseconds;
      writeln;
      writeln2('-----------------------------------------------------------------------');
      writeln2('  [Group 1/5] Generic unit tests in default mode (64-bit preferred):   ');
      writeln2('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDirs;
      WriteStep('a) Compilation step', '-> ');
      CompileAllRunTests(false);
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('b) Run step', '-> ');
      RunAllTests(false);
      WriteStep($'PASSED [{StepTime}]');
      ClearExeDirs;
      writeln2('________________________');
      writeln2($'Elapsed time = {(Milliseconds - GroupTime).ToMinSec}');
    end;
    
    if (ParamCount = 0) or ('2' in ParamSet) then
    begin
      GroupTime := Milliseconds;
      writeln;
      writeln2('-----------------------------------------------------------------------');
      writeln2('  [Group 2/5] Generic unit tests in 32bit mode (forced):               ');
      writeln2('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDirs;
      WriteStep('a) Compilation step', '-> ');
      CompileAllRunTests(false, true);
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('b) Run step', '-> ');
      RunAllTests(false);
      WriteStep($'PASSED [{StepTime}]');
      ClearExeDirs;
      writeln2('________________________');
      writeln2($'Elapsed time = {(Milliseconds - GroupTime).ToMinSec}');
    end;
    
    if (ParamCount = 0) or ('3' in ParamSet) then
    begin
      GroupTime := Milliseconds;
      writeln;
      writeln2('-----------------------------------------------------------------------');
      writeln2('  [Group 3/5] Custom unit tests with PABCRtl.dll (64-bit preferred):   ');
      writeln2('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDirs;
      WriteStep('a) Compilation step (generic samples)', '-> ');
      CompileAllRunTests(true);
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('b) Compilation step (special samples)', '-> ');
      CompileAllCompilationTests('pabcrtl_tests', true);
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('c) Run step (all samples)', '-> ');
      RunAllTests(false);
      WriteStep($'PASSED [{StepTime}]');
      ClearExeDirs;
      writeln2('________________________');
      writeln2($'Elapsed time = {(Milliseconds - GroupTime).ToMinSec}');
    end;
    
    if (ParamCount = 0) or ('4' in ParamSet) then
    begin
      GroupTime := Milliseconds;
      writeln;
      writeln2('-----------------------------------------------------------------------');
      writeln2('  [Group 4/5] Compilation tests of precrafted code samples:            ');
      writeln2('-----------------------------------------------------------------------');
      DeletePCUFiles;
      ClearExeDirs;
      WriteStep('a) ERROR-FREE samples', '-> ');
      CopyLibFiles('CompilationSamples');
      CompileAllCompilationTests('CompilationSamples', false);
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('b) ERROR samples ', '-> ');
      CompileAllUnits;
      CopyPCUFiles;
      CompileAllUsesUnits;
      CompileErrorTests(false);
      WriteStep($'PASSED [{StepTime}]  //by failure, as expected');
      //WriteStep('c) DEMO (bundled) samples', '-> ');
      //WriteStep('N/A           //not implemented yet');
      ClearExeDirs;
      writeln2('________________________');
      writeln2($'Elapsed time = {(Milliseconds - GroupTime).ToMinSec}');
    end;
    
    if (ParamCount = 0) or ('5' in ParamSet) then
    begin
      GroupTime := Milliseconds;
      writeln;
      writeln2('-----------------------------------------------------------------------');
      writeln2('  [Group 5/5] IDE internals tests:                                     ');
      writeln2('-----------------------------------------------------------------------');
      System.Environment.CurrentDirectory := Path.GetDirectoryName(GetEXEFileName());
      WriteStep('a) Intellisense (expressions)', '-> ');
      RunExpressionsExtractTests;
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('b) Intellisense (other)', '-> ');
      RunIntellisenseTests;
      WriteStep($'PASSED [{StepTime}]');
      WriteStep('c) Code Formatter', '-> ');
      CopyLibFiles('formatter_tests\input');
      RunFormatterTests;
      WriteStep($'PASSED [{StepTime}]');
      writeln2('________________________');
      writeln2($'Elapsed time = {(Milliseconds - GroupTime).ToMinSec}');
    end;
  except
    on e: Exception do
      begin
        //assert(false, e.ToString());
        var Message := $'***EXCEPTION: {e.ToString()} + NewLine + {e.Message}';
        Console.Error.WriteLine(NewLine + Message + NewLine);
        Log.WriteLine(Message);
        Log.Flush;
        Halt(-1);
      end;
  end;
  writeln;
  writeln2('________________________________');
  writeln2($'  Total time = {(Milliseconds - StartTime).ToMinSec}');
  writeln;
  writeln('[Compilation, unit and functional tests] >>>>>>>>>>>>>>>>>>>>>>> FINISH');
  writeln;
  Log.Flush;
end.