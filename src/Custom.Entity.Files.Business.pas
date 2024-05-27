unit Custom.Entity.Files.Business;

interface

uses Custom.Entity.Core.Business, Custom.Entity.Core.Model, JOSE.Types.JSON, Custom.Entity.Files.Model,
  Horse.Core.Param, System.Generics.Collections, System.SysUtils,
  Horse, System.Classes;

type
  IEntityFilesBusiness = interface(IEntityCoreBusiness)
    ['{C253A35A-677A-4732-8FFA-32176BFAFBFC}']
    function Get(const AFileName, ADirectory: String): TFileStream; overload;
  end;

  TEntityFilesBusiness = class(TEntityCoreBusiness, IEntityFilesBusiness)
  private
    function GetFiles: TObjectList<TEntityFilesModel>; overload;

    procedure GetFiles(const ADirectory: String; out AResult: TObjectList<TEntityFilesModel>); overload;
    procedure ValidateFile(const AFileName: String);
  public
    class function ModelClass: TEntityCoreModelClass; override;
    function Get(const AParams: THorseCoreParam): TJsonValue; overload; override;
    function Get(const AFileName, ADirectory: String): TFileStream; overload;
  end;

implementation

uses System.IOUtils, Custom.Entity.Core.JSON;

{ TEntityFilesBusiness }

function TEntityFilesBusiness.Get(const AParams: THorseCoreParam): TJsonValue;
begin
  Result := TEntityCoreJSON.ToJsonArray<TEntityFilesModel>(GetFiles);
end;

function TEntityFilesBusiness.Get(const AFileName, ADirectory: String): TFileStream;
begin
  var LFile := ADirectory + TPath.DirectorySeparatorChar + AFileName;

  Result := nil;

  ValidateFile(LFile);

  try
    Result := TFileStream.Create(LFile, fmOpenRead);
    REsult.Position := 0;
  except
    on E: Exception do
    begin
      Result.Free;

      raise EHorseException
                       .New
                       .Title('Não encontrei')
                       .Error('Erro ao tentar carregar o arquivo para fazer o download. Verifique os detalhes da mensagem')
                       .&Type(TMessageType.Error)
                       .Code(062)
                       .Detail(E.Message)
                       .Status(THTTPStatus.NotFound)
                       .Hint('Method Get')
                       .&Unit(Self.UnitName);
    end;
  end;

end;

procedure TEntityFilesBusiness.GetFiles(const ADirectory: String; out AResult: TObjectList<TEntityFilesModel>);
begin
  var LDirectoryList := TDirectory.GetDirectories(ADirectory);

  for var LDiretory in LDirectoryList do
  begin
    GetFiles(LDiretory, AResult);
  end;

  var LFileList := TDirectory.GetFiles(ADirectory);

  for var LFile in LFileList do
  begin
    var LEntityFilesModel := TEntityFilesModel.Create;

    LEntityFilesModel.FileName     := ExtractFileName(LFile);
    LEntityFilesModel.DataFile     := TFile.GetCreationTime(LFile);
    LEntityFilesModel.DataModified := TFile.GetLastWriteTime(LFile);
    LEntityFilesModel.Extension    := ExtractFileExt(LFile).Replace('.', '');
    LEntityFilesModel.Directory    := ExtractFileDir(LFile);
    LEntityFilesModel.Version      := System.SysUtils.GetFileVersion(LFile);

    AResult.Add(LEntityFilesModel);
  end;
end;

function TEntityFilesBusiness.GetFiles: TObjectList<TEntityFilesModel>;
begin
  Result := TObjectList<TEntityFilesModel>.Create;
  GetFiles('files', Result);
end;

class function TEntityFilesBusiness.ModelClass: TEntityCoreModelClass;
begin
  Result := TEntityFilesModel;
end;

procedure TEntityFilesBusiness.ValidateFile(const AFileName: String);
begin
  if not TFile.Exists(AFileName) then
  begin
    raise EHorseException
                       .New
                       .Title('Não encontrei')
                       .Error('O arquivo ' + AFileName + ' não existe!')
                       .&Type(TMessageType.Warning)
                       .Code(061)
                       .Status(THTTPStatus.NotFound)
                       .Hint('Method ValidateFile')
                       .&Unit(Self.UnitName);
  end;
end;

end.
