unit Custom.Entity.Core.DBContext;

interface

uses
  Custom.Entity.Core.Connection, Custom.Entity.Core.Attributes, Custom.Entity.Core.Model, Custom.Entity.Core.Linq, Horse, System.Generics.Collections,
  System.Classes, System.Rtti, Custom.Entity.Core.Types, System.SysUtils;

type
  IEntityCoreDBSet = interface(IQueryAble)
    ['{8A42A8DF-D014-4583-BDDA-82C3D628BC46}']
  end;

  IEntityCoreDBSet<T: TEntityCoreModel> = interface(IEntityCoreDBSet)
    ['{2BF01715-E41C-4A60-A407-7EF1FF87C236}']
    procedure Add(const AObject: T);
    procedure Remove(const AObject: T);
    procedure Update(const AObject: T);
    function Model: T;
  end;

  IEntityCoreDBContext = interface
    ['{56634E35-3A39-4562-9A4A-82046908101A}']
    function GetDBSetByModel(const AClass: TEntityCoreModelClass): TValue;
    function GetConnection: IEntityCoreConnection;

    procedure SaveChanges;

    property Connection: IEntityCoreConnection read GetConnection;
  end;

  TEntityCoreDBContext = class(TInterfacedObject)

  end;


  TEntityCoreDBContext<T: TEntityCoreConnection> = class(TEntityCoreDBContext, IEntityCoreDBContext)
  strict private
    FConnection : IEntityCoreConnection;
  protected
    FSaveChangesList: TObjectList<TEntityCoreModel>;
  private
    procedure CreateDatabase;
    procedure CreateTables(const AClass: TClass);
    procedure CreateDirectoryConfiguration;
    procedure CreateFileConfiguration;
    procedure SetDatabaseNameArchiveConfiguration(const ADatabaseName: String);
    procedure Setconfiguration;
    procedure SaveChanges;

    function GetDBSetByModel(const AClass: TEntityCoreModelClass): TValue;
    function GetConnection: IEntityCoreConnection;
  protected

  public
    constructor Create; virtual;
    destructor Destroy; override;

    property Connection: IEntityCoreConnection read GetConnection;
  end;

  TEntityCoreDBSet<T: TEntityCoreModel> = class(TQueryAble, IEntityCoreDBSet<T>)
  strict private
    FSaveChangesList: TObjectList<TEntityCoreModel>;
    FModel          : T;
  private
    procedure Add(const AObject: T);
    procedure Remove(const AObject: T);
    procedure Update(const AObject: T);
    procedure SetFieldNameInProperties;

    function Model: T;
  public
    constructor Create(ASaveChangeList: TObjectList<TEntityCoreModel>); reintroduce;
    destructor Destroy; override;
  end;

var
  DBContext: IEntityCoreDBContext;

implementation

uses Custom.Entity.Core.Mapper, System.IOUtils, Custom.Entity.Core.Factory, Custom.Entity.Core.Enum, System.TypInfo, Custom.Entity.Core.Server.Helper,
     Custom.Entity.Core.Constant;

{ TEntityCoreDBContext }

procedure TEntityCoreDBContext<T>.Setconfiguration;
begin
  Connection.LoadFromFile(TEntityCoreConstant.cEntityCfg);

  try
    try
      Connection.Open;
    except
      on E: Exception do
      begin
        raise EHorseException
                          .New
                          .Error(E.Message)
                          .Title('Configuração incorreta')
                          .Code(003)
                          .Status(THTTPStatus.InternalServerError)
                          .&Type(TMessageType.Error)
                          .&Unit(UnitName);
      end;
    end;
  finally
    Connection.Close;
  end;
end;

procedure TEntityCoreDBContext<T>.SetDatabaseNameArchiveConfiguration(const ADatabaseName: String);
begin
  var LFile := TStringList.Create;

  var LDatabase := 'Database=' + ADatabaseName;

  try
    LFile.LoadFromFile(TEntityCoreConstant.cEntityCfg);

    if not LFile.Text.ToLower.Contains('database') then
    begin
      LFile.Add(LDatabase);
      LFile.SaveToFile(TEntityCoreConstant.cEntityCfg);
    end;

    Connection.Close;
    Setconfiguration;
  finally
    LFile.Free;
  end;
end;

procedure TEntityCoreDBContext<T>.CreateDatabase;
begin
  if not Connection.IsFirebird then
  begin
    var LDatabaseNameAttribute := TEntityCoreMapper.GetAttribute<DatabaseName>(Self.ClassType);

    if LDatabaseNameAttribute = nil then
    begin
      EHorseException
                  .New
                  .Title('Sem banco de dados')
                  .Error('Não foi informado na classe ' + Self.ClassName + ' o atributo DatabaseName')
                  .Status(THTTPStatus.NotAcceptable)
                  .Detail('Verifique a classe e atribua o atributo DatabaseName na declaracao da classe')
                  .&Type(TMessageType.Error)
                  .&Unit(Self.UnitName)
                  .Hint('Method CreateDatabase');
    end;

    var LDatabaseName := LDatabaseNameAttribute.Value.AsString;

    try
      TEntityCoreFactory.CreateDatabase(LDatabaseName);
    except
      on E: Exception do
      begin
        EHorseException
                    .New
                    .Title('Banco de dados não criado')
                    .Error('Não foi possível criar o banco de dados. Verifique o detalhe da mensagem')
                    .Detail(E.Message)
                    .&Type(TMessageType.Error)
                    .&Unit(Self.UnitName)
                    .Status(THTTPStatus.InternalServerError)
                    .Hint('Method CreateDatabase');
      end;
    end;

     try
      SetDatabaseNameArchiveConfiguration(LDatabaseName);
    except
      on E: Exception do
      begin
        EHorseException
                    .New
                    .Title('Banco de dados não configurado')
                    .Error('Não foi possível configurar o arquivo entity.cfg com os dados do banco de dados. Verifique o detalhe da mensagem')
                    .Detail(E.Message)
                    .&Type(TMessageType.Error)
                    .&Unit(Self.UnitName)
                    .Status(THTTPStatus.InternalServerError)
                    .Hint('Method CreateDatabase');
      end;
    end;
  end;
end;

procedure TEntityCoreDBContext<T>.CreateDirectoryConfiguration;
begin
  if not TDirectory.Exists('configuration') then
  begin
    TDirectory.CreateDirectory('configuration');
  end;
end;

procedure TEntityCoreDBContext<T>.CreateFileConfiguration;
begin

  if not TFile.Exists(TEntityCoreConstant.cEntityCfg) then
  begin
    try
      TFile.WriteAllText(TEntityCoreConstant.cEntityCfg, Connection.GetDefaultConfiguration);
    except
      on E: Exception do
      begin
        raise EHorseException
                           .New
                           .Error(E.Message)
                           .Title('Gerar o arquivo cfg')
                           .Status(THTTPStatus.Continue)
                           .Detail('Erro ao tentar gerar o arquivo ' + TEntityCoreConstant.cEntityCfg)
                           .&Unit(Self.UnitName)
                           .&Type(TMessageType.Error).Code(001);
      end;
    end;

    raise EHorseException
                      .New
                      .Error('O arquivo ' + TEntityCoreConstant.cEntityCfg + ' não está configurado com o acesso ao banco de dados.')
                      .Title('Sem configuração')
                      .Status(THTTPStatus.Continue)
                      .Detail('Após configurar o arquivo, reinicie o servidor ou serviço')
                      .&Unit(Self.UnitName)
                      .&Type(TMessageType.Warning)
                      .Code(002);
  end;
end;

procedure TEntityCoreDBContext<T>.CreateTables(const AClass: TClass);
begin
  var LFields := TEntityCoreMapper.GetFields(AClass);

  try
    for var LField in LFields do
    begin
      var LFieldClassName := LField.FieldType.Name;

      if not LFieldClassName.Contains('EntityCoreDBSet') then
      begin
        Continue;
      end;

      var LClass := TEntityCoreModelClass(FindClass(LFieldClassName
                                                   .Substring(LFieldClassName.LastIndexOf('.') + 1)
                                                   .Replace('IEntityCoreDBSet<', '')
                                                   .Replace('>', '')));

      try
        TEntityCoreFactory.CreateTable(LClass);
      except
        on E: EHorseException do
        begin
          raise;
        end;

        on E: Exception do
        begin
          raise EHorseException
                             .New
                             .Title('Ocorreu algo!')
                             .Status(THTTPStatus.BadRequest)
                             .Error('Erro ao tentar verificar tabela ' + LClass.ClassName)
                             .&Type(TMessageType.Error)
                             .Detail(E.Message)
                             .&Unit(UnitName)
                             .Code(009)
                             .Hint('método CreateTable');
        end;
      end;
    end;
  finally
    Connection.Close;
  end;
end;

destructor TEntityCoreDBContext<T>.Destroy;
begin
  FSaveChangesList.Free;
  inherited;
end;

function TEntityCoreDBContext<T>.GetConnection: IEntityCoreConnection;
begin
  if FConnection = nil then
  begin
    FConnection := TEntityCoreMapper
                              .GetMethod<T>('Create')
                              .Invoke(T, [])
                              .AsType<IEntityCoreConnection>;
  end;

  Result := FConnection;
end;

constructor TEntityCoreDBContext<T>.Create;
begin
  inherited;
  DBContext := Self;
  CreateDirectoryConfiguration;
  CreateFileConfiguration;
  Setconfiguration;
  CreateDatabase;
  CreateTables(Self.ClassParent);
  CreateTables(Self.ClassType);
  FSaveChangesList := TObjectList<TEntityCoreModel>.Create;
end;

{ TEntityCoreDBContext }

procedure TEntityCoreDBContext<T>.SaveChanges;
begin
  Connection.BeginTransaction;
  try
    for var LModel in FSaveChangesList do
    begin
      case LModel.Status of
        TEntityCoreModelStatus.Inserted:
          begin
            var
              LIdKey: Int64;

            Connection.InsertRecord(LModel, LIdKey);
            LModel.ProcedureIdKey(LIdKey);
          end;
        TEntityCoreModelStatus.Updated:
          begin
            Connection.UpdateRecord(LModel);
          end;
        TEntityCoreModelStatus.Deleted:
          ;
      end;

      FSaveChangesList.Remove(LModel);
    end;
    Connection.CommitTransaction;
  except
    on E: EHorseException do
    begin
      Connection.RollbackTransaction;
      raise;
    end;
    on E: Exception do
    begin
      Connection.RollBackTransaction;
      raise EHorseException
                         .New
                         .Title('Não inseriu!')
                         .Error(E.Message)
                         .&Unit('Custom.Entity.Core.DBContext')
                         .Status(THTTPStatus.InternalServerError)
                         .&Type(TMessageType.Error)
                         .&Hint('Method SaveChanges')
                         .Code(014);
    end;
  end;
end;

{ TEntityCoreDBSet<T> }

procedure TEntityCoreDBSet<T>.Add(const AObject: T);
begin
  TEntityCoreModel(AObject).Status := TEntityCoreModelStatus.Inserted;
  FSaveChangesList.Add(AObject.Clone);
end;

constructor TEntityCoreDBSet<T>.Create(ASaveChangeList: TObjectList<TEntityCoreModel>);
begin
  inherited Create(T);
  FSaveChangesList := ASaveChangeList;
  FModel := TEntityCoreMapper
                         .GetMethod<T>('Create')
                         .Invoke(T, [])
                         .AsType<T>;

  SetFieldNameInProperties;
end;

destructor TEntityCoreDBSet<T>.Destroy;
begin
  FModel.Free;
  inherited;
end;

function TEntityCoreDBSet<T>.Model: T;
begin
  Result := FModel;
end;

procedure TEntityCoreDBSet<T>.Remove(const AObject: T);
begin
  TEntityCoreModel(AObject).Status := TEntityCoreModelStatus.Deleted;
  FSaveChangesList.Add(AObject.Clone);
end;

procedure TEntityCoreDBSet<T>.SetFieldNameInProperties;
begin
  var LPropertiesList     := TEntityCoreMapper.GetProperties<T>;
  var LTableNameAttribute := TEntityCoreMapper.GetAttribute<T, TableName>;

  if LTableNameAttribute <> nil then
  begin
    var LTableName := LTableNameAttribute
                                     .Value
                                     .AsString
                                     .ToUpper;

    for var LProperty in LPropertiesList do
    begin
      if LProperty.IsNullable then
      begin
        var LValue := LProperty.GetValue(TObject(FModel));

        TEntityCoreMapper
                   .GetType(LValue.TypeInfo)
                   .GetMethod('SetName')
                   .Invoke(LValue,
                           [Format('%s.%s',
                                  [LTableName,
                                   LProperty.Name.ToUpper])
                           ]);

        LProperty.SetValue(TObject(FModel), LValue);
      end;
    end;
  end;
end;

procedure TEntityCoreDBSet<T>.Update(const AObject: T);
begin
  TEntityCoreModel(AObject).Status := TEntityCoreModelStatus.Updated;
  FSaveChangesList.Add(AObject.Clone);
end;

function TEntityCoreDBContext<T>.GetDBSetByModel(const AClass: TEntityCoreModelClass): TValue;
begin
  Result := nil;

  var
  LFieldList := TEntityCoreMapper
                           .GetType(Self.ClassType)
                           .GetFields;

  for var LField in LFieldList do
  begin
    if AClass.ClassName.Contains(LField.Name.Remove(0, 1)) then
      Exit(LField
             .GetValue(Self));
  end;
end;

end.
