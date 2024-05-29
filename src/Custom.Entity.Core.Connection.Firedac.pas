unit Custom.Entity.Core.Connection.Firedac;

interface

uses Custom.Entity.Core.Connection,
     Firedac.Comp.Client,
     System.Generics.Collections,
     Data.DB,
     Custom.Entity.Core.Model,
     FireDAC.Stan.Param,
     System.Classes,
     FireDAC.Stan.Def,
     FireDAC.Stan.Async,
     FireDAC.DApt,
     FireDAC.Phys.SQLite,
     FireDAC.Phys.MSSQL,
     FireDAC.Phys.FB,
     FireDAC.Phys.Oracle,
     FireDAC.Phys.PG,
  Horse;

type
  IEntityCoreConnectionFiredac = interface(IEntityCoreConnection)
    ['{5C9E1777-1958-4910-B8C1-A21A3352045F}']
    function ExecSQL(const ASQL: String; AParams: TFDParams): LongInt; overload;
    function ExecSQL(const ASQL: String; AParams: TFDParams; var AResultSet: TDataSet): LongInt; overload;
  end;

  TEntityCoreConnectionFiredac = class(TFDConnection, IEntityCoreConnectionFiredac)
  private
    function ExecSQL(const ASQL: String; AParams: TParams): LongInt; overload;
    function ExecSQL(const ASQL: String; AParams: TParams; var AResultSet: TDataSet): LongInt; overload;
    function GetDefaultConfiguration: String;
    function IsFirebird: Boolean;
    function IsSQLite: Boolean;
    function IsSQLServer: Boolean;
    function IsMySQL: Boolean;
    function TableExists(const ATableName: String): Boolean;
    function FieldExists(const ATableName, AFieldName: String): Boolean;
    function DatabaseExists(const ADatabaseName: String): Boolean;
    function UniqueKeyExists(const ATableName, AUniquekeyName: String): String;
    function SupportedJson: Boolean;

    procedure SetConfiguration(const ADatabaseName: String); overload;
    procedure SetConfiguration(const ADriverID, AServer: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure LoadFromFile(const AFileName: String);
    procedure InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
    procedure UpdateRecord(const AModel: TEntityCoreModel);
  public
    constructor Create(AOwner: TComponent); override;
    class function New: IEntityCoreConnectionFiredac;
  end;

implementation

uses
  System.Variants, System.SysUtils, Custom.Entity.Core.Constant, Custom.Entity.Core.Server.Helper, Custom.Entity.Core.Factory;

{ TEntityConnectionFiredac }


constructor TEntityCoreConnectionFiredac.Create(AOwner: TComponent);
begin
  inherited;
  Self.LoginPrompt                 := False;
  Self.UpdateOptions.FastUpdates   := True;
  Self.FetchOptions.Unidirectional := True;
  Self.FetchOptions.AutoClose      := True;
  Self.FetchOptions.RowsetSize     := 50;
  Self.ConnectedStoredUsage        := [];
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: String; AParams: TParams): LongInt;
begin
  Result := ExecSQL(ASQL, TFDParams(AParams));
end;

function TEntityCoreConnectionFiredac.DatabaseExists(const ADatabaseName: String): Boolean;
begin
  var LDatabaseExists := '';

  if IsSQLServer then
  begin
    LDatabaseExists := TEntityCoreConstant.cDatabaseExistsSQLServer;
  end;

  Result := ExecSQLScalar(LDatabaseExists, [ADatabaseName]) <> 0;
end;

function TEntityCoreConnectionFiredac.ExecSQL(const ASQL: String; AParams: TParams; var AResultSet: TDataSet): LongInt;
begin
  Result := ExecSQL(ASQL, TFDParams(AParams), AResultSet);
end;

function TEntityCoreConnectionFiredac.FieldExists(const ATableName, AFieldName: String): Boolean;
begin
  var LFieldExists := '';

  if IsFirebird then
  begin
    LFieldExists := TEntityCoreConstant.cFieldExistsFirebird;
  end
  else if IsSQLServer then
  begin
    LFieldExists := TEntityCoreConstant.cFieldExistsSQLServer;
  end;

  Result := ExecSQLScalar(LFieldExists,
                          [ATableName.ToUpper,
                           AFieldName.ToUpper]) <> 0;
end;

function TEntityCoreConnectionFiredac.GetDefaultConfiguration: String;
begin
  Result := Concat('DriverID=%s', #13,
                   'Server=%s', #13,
                   'User_Name=%s', #13,
                   'Password=%s', #13);
end;

procedure TEntityCoreConnectionFiredac.InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
begin
  var LDataSet: TDataSet := nil;
  try
    try
      var LRecordInsert := TEntityCoreFactory.RecordInsert(AModel);

      ExecSQL(LRecordInsert.Insert, LRecordInsert.Params, LDataSet);

      AIdKey := LDataSet.Fields[0].AsVariant;
    except
      raise;
//      on E: Exception do
//      begin
//        raise EHorseException
//                          .New
//                          .Title('Ops... Algo de errado')
//                          .Error('Erro ao gerar o script do registro da tabela ' + TEntityCoreMapper.GetTableName(AModel.ClassType))
//                          .Detail(E.Message)
//                          .Status(THTTPStatus.InternalServerError)
//                          .&Type(TMessageType.Error)
//                          .&Unit(Self.UnitName)
//                          .Hint('Method InsertRecord')
//                          .Code(022)
//      end;
    end;
  finally
    LDataSet.Free;
  end;
end;

function TEntityCoreConnectionFiredac.IsFirebird: Boolean;
begin
  Result := DriverName.Equals('FB');
end;

function TEntityCoreConnectionFiredac.IsMySQL: Boolean;
begin
  Result := DriverName.Equals('MySQL')
end;

function TEntityCoreConnectionFiredac.IsSQLite: Boolean;
begin
  Result := DriverName.Equals('SQLite');
end;

function TEntityCoreConnectionFiredac.IsSQLServer: Boolean;
begin
  Result := DriverName.Equals('MSSQL');
end;

procedure TEntityCoreConnectionFiredac.LoadFromFile(const AFileName: String);
begin
  Params.LoadFromFile(AFileName);
end;

class function TEntityCoreConnectionFiredac.New: IEntityCoreConnectionFiredac;
begin
  Result := Self.Create(nil);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer: String);
begin
  SetConfiguration(ADriverID, AServer, '', '');
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName: String);
begin
  try
    Close;
    Params.Database := ADatabaseName;
    Open;
    Close;
  except
    on E: Exception do
    begin
      raise EHorseException
                      .New
                      .Title('Nome do banco de dados')
                      .Error(E.Message)
                      .Status(THTTPStatus.InternalServerError)
                      .&Type(TMessageType.Error)
                      .Code(006)
                      .&Unit(UnitName)
                      .Hint('Line 116')
                      .Detail('Verificar com o suporte técnico sobre a mensagem de erro apresentada');
    end;
  end;
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer, AUserName, APassword: String);
begin
  SetConfiguration(ADriverID, AServer, AUserName, APassword, 0);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADriverID, AServer, AUserName, APassword: String; APort: Integer);
begin
  SetConfiguration('', ADriverID, AServer, AUserName, APassword, APort);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String);
begin
  SetConfiguration(ADatabaseName, ADriverID, AServer, AUserName, APassword, 0);
end;

procedure TEntityCoreConnectionFiredac.SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String;
  APort: Integer);
begin
  try
    Close;
    Params.Database := ADatabaseName;
    Params.UserName := AUserName;
    Params.Password := APassword;
    DriverName      := ADriverID;
    Params.AddPair('Server', AServer);

    if APort > 0 then
    begin
      Params.AddPair('Port', APort.ToString);
    end;

    Open;
    Close;
  except
    on E: Exception do
    begin
      raise EHorseException
                      .New
                      .Title('Erro ao tentar configurar o banco de dados')
                      .Error(E.Message)
                      .Status(THTTPStatus.InternalServerError)
                      .&Type(TMessageType.Error)
                      .Code(007)
                      .&Unit(UnitName)
                      .Hint('Line 116')
                      .Detail('Verificar com o suporte técnico sobre a mensagem de erro apresentada');
    end;
  end;
end;

function TEntityCoreConnectionFiredac.SupportedJson: Boolean;
begin
  Result := False;
end;

function TEntityCoreConnectionFiredac.TableExists(const ATableName: String): Boolean;
begin
  var LTableExists := '';

  if IsFirebird then
  begin
    LTableExists := TEntityCoreConstant.cTableExistsFirebird;
  end
  else if IsSQLServer then
  begin
    LTableExists := TEntityCoreConstant.cTableExistsSQLServer;
  end;

  Result := ExecSQLScalar(LTableExists, [ATableName.ToUpper]) <> 0;
end;

function TEntityCoreConnectionFiredac.UniqueKeyExists(const ATableName, AUniquekeyName: String): String;
begin
  var LSelectUniqueKey   := '';
  var LDataSet: TDataSet := nil;
  var LParams            := TParams.Create(nil);

  try
    try
      if IsFirebird then
      begin
        LSelectUniqueKey := TEntityCoreConstant.cUniqueKeyExistsFirebird;
      end
      else if IsSQLServer then
      begin
        LSelectUniqueKey := TEntityCoreConstant.cUniqueKeyExistsSQLServer;
      end;

      LParams
         .AddParameter
         .SetNameValue('tablename',
                       ATableName.ToUpper);

      LParams
         .AddParameter
         .SetNameValue('uniquekey',
                       AUniquekeyName.Insert(0, 'uq_').ToUpper);

      ExecSQL(LSelectUniqueKey,
              LParams,
              LDataSet);

      Result := LDataSet.Fields[0].AsString;
    except
      on E: Exception do
      begin
        raise EHorseException
                           .New
                           .Error(E.Message)
                           .Title('Erro ao verificar unique key')
                           .Status(THTTPStatus.InternalServerError)
                           .&Detail('Falha na execução do sql')
                           .&Unit(Self.UnitName)
                           .&Type(TMessageType.Error)
                           .Code(070);
      end;
    end;
  finally
    LDataSet.Free;
    LParams.Free;
  end;
end;

procedure TEntityCoreConnectionFiredac.UpdateRecord(const AModel: TEntityCoreModel);
begin
  var LRecordUpdate := TEntityCoreFactory.RecordUpdate(AModel);

  if not LRecordUpdate.Update.Trim.IsEmpty then
  begin
    ExecSQL(LRecordUpdate.Update, LRecordUpdate.ArrayParams);
  end;
//      raise EHorseException
//                        .New
//                        .Title('Ops... Algo de errado')
//                        .Error('Erro ao gerar o script do registro da tabela ' + TEntityCoreMapper.GetTableName(AModel.ClassType))
//                        .Detail(E.Message)
//                        .Status(THTTPStatus.InternalServerError)
//                        .&Type(TMessageType.Error)
//                        .&Unit(Self.UnitName)
//                        .Hint('Method UpdateRecord')
//                        .Code(028)
end;

end.
