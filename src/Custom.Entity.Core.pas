unit Custom.Entity.Core;

interface

uses Horse,
     Horse.Etag,
     Horse.Jhonson,
     Horse.Paginate,
     Horse.HandleException,
     Horse.JWT,
     Horse.OctetStream,
     Custom.Entity.Core.Constant,
     Custom.Entity.Core.DBContext,
     System.Classes,
     System.Types,
     Custom.Enitty.Core.Service;

type
  TEntity = class(THorse)
  strict private
    class var FHtml : String;
    class var FError: String;
  private
    procedure CreateDirectoryLog;
    procedure CreateDirectoryFiles;
    class procedure ExtractToFile(const AFileName: String);
    class procedure Register;
  public
    constructor Create; override;

    class function Html(const AHtml: String): TEntity;
    class function DBContext<I: IEntityCoreDBContext; T: TEntityCoreDBContext>(var AIEntityCoreDBSet: I): TEntity;
    class function Resource(const AResourceName: String): TEntity; overload;
    class function Resource(const AResourceName: String; const ADirectoryExport: String): TEntity; overload;
    class function Resource(const AResourceName: String; const ADirectoryExport: String; const AExtractFileZip: Boolean): TEntity; overload;
    class function RegisterService<T: TEntityCoreService>: TEntity;
    class function OnBeforeListen(const AProcedure: TProc): TEntity;
    class function GetInstance: TEntity; reintroduce;
  end;

implementation

uses
  System.SysUtils,
  Custom.Entity.Core.Mapper,
  System.IOUtils,
  Horse.Exception,
  System.Zip;

{ TEntity }

constructor TEntity.Create;
begin
  inherited;
  FHtml := TEntityCoreConstant.cHtml;
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  CreateDirectoryLog;
  CreateDirectoryFiles;

  Self.OnListen := procedure
                   begin
                     Self.Register;
                   end;

  Self
    .Use(Jhonson)
    .Use(Etag)
    .Use(Paginate)
    .Use(HandleException)
    .Use(OctetStream);
end;

procedure TEntity.CreateDirectoryFiles;
begin
  if not TDirectory.Exists('files') then
  begin
    TDirectory.CreateDirectory('files');
  end;
end;

procedure TEntity.CreateDirectoryLog;
begin
  if not TDirectory.Exists('log') then
  begin
    TDirectory.CreateDirectory('log');
  end;
end;

class function TEntity.DBContext<I, T>(var AIEntityCoreDBSet: I): TEntity;
begin
  Result := GetInstance;
  if (AIEntityCoreDBSet = nil) then
  begin
    try
      AIEntityCoreDBSet := TEntityCoreMapper
                                        .GetMethod<T>('Create')
                                        .Invoke(T, [])
                                        .AsType<I>;
    except
      on E: EHorseException do
      begin
        FError := E.ToJSON;
        TFile.WriteAllText('logs/Errorlog' + FormatDateTime('ddmmmyyyy_hhmm', Now) + '.json', FError);
        Writeln(E.ClassName, ':', FError);
      end;
    end;
  end;
end;

class procedure TEntity.ExtractToFile(const AFileName: String);
begin
  if AFileName.Contains('.zip') or AFileName.Contains('.rar') then
  begin
    var LZip := TZipFile.Create;
    try
      try
        LZip.Open(AFileName,
                  TZipMode.zmRead);
        LZip.ExtractAll(ExtractFilePath(AFileName));
      except
        raise;
      end;
    finally
      LZip.Free;
    end;
  end;
end;

class function TEntity.GetInstance: TEntity;
begin
  Result := (inherited GetInstance) as TEntity;
end;

class function TEntity.Html(const AHtml: String): TEntity;
begin
  Result := GetInstance;
  if not AHtml.Trim.IsEmpty then
  begin
    FHtml := AHtml;
  end;
end;

class function TEntity.OnBeforeListen(const AProcedure: TProc): TEntity;
begin
  Result := GetInstance;
  Self.OnListen := AProcedure;
end;

class function TEntity.Resource(const AResourceName: String): TEntity;
begin
  Result := Resource(AResourceName, 'files');
end;

class function TEntity.Resource(const AResourceName, ADirectoryExport: String): TEntity;
begin
  Result := Resource(AResourceName, ADirectoryExport, True);
end;

class procedure TEntity.Register;
begin
  Self.Get('',
           procedure(ARes: THorseResponse)
           begin
             ARes.Send(FHtml.Replace('@@error', 'Error:' + FError));
           end);
end;

class function TEntity.RegisterService<T>: TEntity;
begin
  Result := GetInstance;

  TEntityCoreMapper
               .GetMethod<T>('New')
               .Invoke(T, [])
               .AsType<IEntityCoreService>
               .Register;
end;

class function TEntity.Resource(const AResourceName, ADirectoryExport: String; const AExtractFileZip: Boolean): TEntity;
begin
  Result := GetInstance;

  var LResource := TResourceStream.Create(HInstance,
                                          AResourceName,
                                          RT_RCDATA);
  try
    try
      LResource.Position := 0;
      LResource.SaveToFile(ADirectoryExport + TPath.DirectorySeparatorChar + AResourceName);

      if AExtractFileZip then
      begin
        ExtractToFile(ADirectoryExport + TPath.DirectorySeparatorChar + AResourceName);
      end;
    except
      on E: Exception do
      begin
        TFile.WriteAllText('logs/Errorlog' + FormatDateTime('ddmmmyyyy_hhmm', Now) + '.json', E.Message);
        Writeln(E.ClassName, ':', E.Message);
      end;
    end;
  finally
    LResource.Free;
  end;
end;

end.
