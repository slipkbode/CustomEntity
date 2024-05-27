unit Custom.Entity.Core.Business;

interface

uses
  System.JSON, System.Generics.Collections, Custom.Entity.Core.DAO,
  System.Rtti, Custom.Entity.Core.JSON, System.SysUtils, Horse.Exception,
  Horse, Custom.Entity.Core.Model, Custom.Entity.Core.Types,
  Custom.Entity.Core.Enum, JOSE.Core.JWT, JOSE.Context;

type
  IEntityCoreBusiness = interface
    ['{481E8991-4F24-41D8-B2AA-16C73F4338E6}']
    function Get: TJsonValue; overload;
    function Get(const AParams: THorseCoreParam): TJsonValue; overload;
    function Post(const AJsonObject: TJSONObject): TEntityCoreModel; overload;
    function Post(const AObject: TEntityCoreModel): TEntityCoreModel; overload;

    procedure Put(const AObject: TEntityCoreModel; AParam: TArray<TPair<String, String>>); overload;
    procedure Put(const AJsonObject: TJSONObject; AParam: TArray<TPair<String, String>>); overload;
  end;

  TEntityCoreBusiness = class(TInterfacedObject, IEntityCoreBusiness)
  protected
    FSession: TValue;
    FHeader : TArray<TValue>;
    procedure Validate(const AObject: TEntityCoreModel); virtual;
    procedure ValidateNotNull(const AObject: TEntityCoreModel; const AModelStatus: TEntityCoreModelStatus); overload;
    procedure ValidateNotNull(const AObject: TEntityCoreModel); overload;
    procedure ValidateObjectNil(const AObject: TEntityCoreModel; const AMethodName: String);
    procedure ValidatePrimaryKey(const AObject: TEntityCoreModel);
    procedure ValidateFind(const AObject: TEntityCoreModel);
    procedure Put(const AObject: TEntityCoreModel; AParam: TArray<TPair<String, String>>); overload; virtual; abstract;
    procedure Put(const AJsonObject: TJSONObject; AParam: TArray<TPair<String, String>>); overload; virtual; abstract;
    function GetSession<J: TJWTClaims>(const AToken: String): J; overload;
    function GetSession<J: TJWTClaims>: J; overload;

    function Get: TJsonValue; overload; virtual;
    function Get(const AParams: THorseCoreParam): TJsonValue; overload; virtual;
    function Post(const AJsonObject: TJSONObject): TEntityCoreModel; overload; virtual; abstract;
    function Post(const AObject: TEntityCoreModel): TEntityCoreModel; overload; virtual; abstract;

  public
    class function ModelClass: TEntityCoreModelClass; virtual;

    constructor Create(const AParameter: TArray<TValue>); reintroduce; virtual;
  end;

  TEntityCoreBusiness<T: TEntityCoreDAO; I: IEntityCoreDAO> = class(TEntityCoreBusiness)
  private
    procedure SetPrimaryKey(const AObject: TEntityCoreModel); overload;
    procedure MergeObject(const AJsonObject: TJSONObject; ADestObject: TObject);
  protected
    DAO: I;
  protected
    function Get: TJsonValue; override;
    function Get(const AParams: THorseCoreParam): TJsonValue; override;
    function Post(const AJsonObject: TJSONObject): TEntityCoreModel; override;
    function Post(const AObject: TEntityCoreModel): TEntityCoreModel; override;

    procedure BeforePost(AObject: TEntityCoreModel); virtual;
    procedure AfterPost(AObject: TEntityCoreModel); virtual;
    procedure BeforePut(AObject: TEntityCoreModel; AJsonObject: TJsonObject); virtual;
    procedure AfterPut(AObject: TEntityCoreModel); virtual;

    procedure Put(const AObject: TEntityCoreModel; AParam: TArray<TPair<String, String>>); override;
    procedure Put(const AJsonObject: TJSONObject; AParam: TArray<TPair<String, String>>); override;
  public
    class function ModelClass: TEntityCoreModelClass; override;

    constructor Create(const AParameter: TArray<TValue>); override;
  end;

implementation

uses Custom.Entity.Core.Mapper, Custom.Entity.Core.Server.Helper, System.TypInfo;

{ TEntityCoreBusiness }

procedure TEntityCoreBusiness<T, I>.AfterPost(AObject: TEntityCoreModel);
begin
end;

procedure TEntityCoreBusiness<T, I>.AfterPut(AObject: TEntityCoreModel);
begin
end;

procedure TEntityCoreBusiness<T, I>.BeforePost(AObject: TEntityCoreModel);
begin
end;

procedure TEntityCoreBusiness<T, I>.BeforePut(AObject: TEntityCoreModel; AJsonObject: TJsonObject);
begin
end;

constructor TEntityCoreBusiness<T, I>.Create(const AParameter: TArray<TValue>);
begin
  inherited;
  DAO := TEntityCoreMapper
                     .GetMethod<T>('Create')
                     .Invoke(TClass(T), [])
                     .AsType<I>;
end;

function TEntityCoreBusiness<T, I>.Get(const AParams: THorseCoreParam): TJsonValue;
begin
  try
    var LValue := TEntityCoreMapper
                              .GetMethod<T>('Get', ['AParams'])
                              .Invoke(DAO as T, TValue.From(AParams.ToArray));

    if LValue.IsEmpty then
    begin
      Result := TJSONNull.Create;
    end
    else
    begin
      Result := TEntityCoreJson.ToJsonArray(TObjectList<TObject>(LValue.AsObject));
    end;
  except
    on E: EHorseException do
    begin
      raise;
    end;
    on E: Exception do
    begin
      raise EHorseException
                       .New
                       .Title('Erro ao efetuar o Get!')
                       .Status(THTTPStatus.BadRequest)
                       .Error(E.Message)
                       .&Type(TMessageType.Error)
                       .Detail('Erro ao retorno o json com os registros do get')
                       .&Unit(UnitName)
                       .Code(008)
                       .Hint('método Get');
    end;
  end;
end;

procedure TEntityCoreBusiness<T, I>.MergeObject(const AJsonObject: TJSONObject; ADestObject: TObject);
begin
  var LType := TEntityCoreMapper.GetType(ADestObject.ClassType);

  for var LJsonPair in AJsonObject do
  begin
    var LDestProperty := LType.GetProperty(LJsonPair.JsonString.Value);

    if (LDestProperty <> nil) then
    begin
      LDestProperty.FromJSON(ADestObject, LJsonPair.JsonValue);
    end;
  end;
end;

class function TEntityCoreBusiness<T, I>.ModelClass: TEntityCoreModelClass;
begin
  inherited;
  Result := TEntityCoreMapper
                         .GetMethod<T>('ModelClass')
                         .Invoke(T, [])
                         .AsType<TEntityCoreModelClass>;
end;

function TEntityCoreBusiness<T, I>.Post(const AObject: TEntityCoreModel): TEntityCoreModel;
begin
  Validate(AObject);
  ValidateObjectNil(AObject, 'inclusão');

  SetPrimaryKey(AObject);
  BeforePost(AObject);
  TEntityCoreMapper
            .GetMethod<T>('Post')
            .Invoke(TEntityCoreDAO(DAO), [AObject]);
  AfterPost(AObject);
  Result := AObject;
end;

procedure TEntityCoreBusiness<T, I>.Put(const AJsonObject: TJSONObject; AParam: TArray<TPair<String, String>>);
begin
  var LModel: TEntityCoreModel := nil;

  try
    try
      var LValue := TEntityCoreMapper
                            .GetMethod<T>('Get', ['AParams'])
                            .Invoke(TEntityCoreDAO(DAO),
                                   [TValue.From(AParam)]);

      LModel := TObjectList<TObject>(LValue.AsObject).Items[0] as TEntityCoreModel;

      ValidateFind(LModel);
      BeforePut(LModel, AJsonObject);
      MergeObject(AJsonObject, LModel);
      Put(LModel, AParam);
    except
      on E: EHorseException do
      begin
        raise;
      end;

      on E: Exception do
      begin
        raise EHorseException
                          .New
                          .Title('Erro ao efetuar a atualização')
                          .Error('Não foi possível atualizar os dados. Verifique o detalhe da mensagem')
                          .Detail(E.Message)
                          .&Type(TMessageType.Error)
                          .&Unit(SElf.UnitName)
                          .Hint('Method Put')
                          .Code(035)
                          .Status(THTTPStatus.InternalServerError);
      end;
    end;
  finally
    LModel.Free;
  end;
end;

procedure TEntityCoreBusiness<T, I>.Put(const AObject: TEntityCoreModel; AParam: TArray<TPair<String, String>>);
begin
  ValidateObjectNil(AObject, 'alteração');
  ValidateNotNull(AObject, TEntityCoreModelStatus.Updated);
  ValidatePrimaryKey(AObject);

  TEntityCoreMapper
             .GetMethod<T>('Put')
             .Invoke(TEntityCoreDAO(DAO),
                     [AObject]);
  AfterPut(AObject);
end;

procedure TEntityCoreBusiness<T, I>.SetPrimaryKey(const AObject: TEntityCoreModel);
begin
  var LPrimaryKey := TEntityCoreMapper.GetPrimaryKey(AObject.ClassType);

  if (LPrimaryKey <> nil) and LPrimaryKey.IsAutoIncrement then
  begin
    var LId: Nullable<Integer> := TEntityCoreMapper
                                               .GetMethod<T>('GetSequencePrimaryKey')
                                               .Invoke(DAO as T, [LPrimaryKey])
                                               .AsInt64;

    LPrimaryKey.SetValue(AObject,
                         TValue.From(LId));
  end;
end;

function TEntityCoreBusiness<T, I>.Post(const AJsonObject: TJSONObject): TEntityCoreModel;
begin
  var LObject: TObject := nil;

  TEntityCoreJSON.JsonToObject(ModelClass,
                               AJsonObject,
                               '',
                               LObject);

  Result := Post(LObject as TEntityCoreModel);
end;

function TEntityCoreBusiness<T, I>.Get: TJsonValue;
begin
  inherited;
  Result := Get(nil);
end;

procedure TEntityCoreBusiness.ValidateNotNull(const AObject: TEntityCoreModel; const AModelStatus: TEntityCoreModelStatus);
begin
  var LProperties := TEntityCoreMapper.GetProperties(AObject.ClassType);

  for var LProperty in LProperties do
  begin
    if LProperty.IsNotNull and (LProperty.IsNull(AObject)) then
    begin
       raise EHorseException
                          .New
                          .Code(012)
                          .Error('O campo ' + LProperty.Name + ' não pode ser nulo ou vazio!')
                          .&Title('Objeto inválido')
                          .&Unit(Self.UnitName)
                          .Status(THTTPStatus.NotAcceptable)
                          .&Type(TMessageType.Warning)
                          .Detail('Verifique o objeto ' + AObject.ClassName + ' que foi passado via post no endpoint');
    end;
  end;
end;

{ TEntityCoreBusiness }

function TEntityCoreBusiness.Get: TJsonValue;
begin
  Result := Get(nil);
end;

function TEntityCoreBusiness.Get(const AParams: THorseCoreParam): TJsonValue;
begin
  Result := nil;
end;

function TEntityCoreBusiness.GetSession<J>: J;
begin
  Result := FSession.AsType<J>;
end;

class function TEntityCoreBusiness.ModelClass: TEntityCoreModelClass;
begin
  Result := nil;
end;

function TEntityCoreBusiness.GetSession<J>(const AToken: String): J;
var
  LJWT: TJOSEContext;
begin
  LJWT := TJOSEContext.Create(AToken, J);

  try
    try
      if LJWT.GetJOSEObject = nil then
      begin
        raise Exception.Create('Não está válido o token');
      end;

      Result      := J.Create;
      Result.JSON := LJWT.GetClaims.JSON.Clone as TJSONObject;
    except
      on E: Exception do
      begin
        raise EHorseCallbackInterrupted.Create(E.Message);
      end;
    end;
  finally
    LJWT.Free;
  end;
end;

constructor TEntityCoreBusiness.Create(const AParameter: TArray<TValue>);
begin
  for var LValue in AParameter do
  begin
    if not LValue.IsEmpty then
    begin
      if LValue.IsObject and (LValue.TypeInfo.TypeData.ClassType.ClassParent = TJWTClaims) then
      begin
        FSession := LValue;
      end
      else
      begin
        Insert(LValue, FHeader, Length(FHeader));
      end;
    end;
  end;
end;

procedure TEntityCoreBusiness.Validate(const AObject: TEntityCoreModel);
begin
  ValidateNotNull(AObject);
end;

procedure TEntityCoreBusiness.ValidateFind(const AObject: TEntityCoreModel);
begin
  if AObject = nil then
  begin
    raise EHorseException
                      .New
                      .Title('Não encontrado!')
                      .Error('Não foi encontrado o registro com os filtros para atualizar na tabela')
                      .Code(030)
                      .Status(THTTPStatus.NotFound)
                      .&Type(TMessageType.Warning)
                      .&Unit(Self.UnitName)
                      .Detail('O parâmetro utilizado para fazer a pesquisa para a alteração não existe valores que possa retornar o registro')
                      .Hint('Method ValidateFind');
  end;
end;

procedure TEntityCoreBusiness.ValidateNotNull(const AObject: TEntityCoreModel);
begin
  ValidateNotNull(AObject, TEntityCoreModelStatus.Inserted);
end;

procedure TEntityCoreBusiness.ValidateObjectNil(const AObject: TEntityCoreModel; const AMethodName: String);
begin
  if AObject = nil then
  begin
    raise EHorseException
                       .New
                       .Error('O objeto para ' + AMethodName + ' do registro está vazio')
                       .Title('Sem objeto do model')
                       .Detail('Informe um objeto model para fazer a '+ AMethodName +' do registro')
                       .&Unit(Self.UnitName)
                       .&Type(TMessageType.Warning)
                       .Code(021)
                       .Status(THTTPStatus.NotAcceptable)
                       .Hint('Method ' + AMethodName);
  end;
end;

procedure TEntityCoreBusiness.ValidatePrimaryKey(const AObject: TEntityCoreModel);
begin
  var LPrimaryKey := TEntityCoreMapper.GetPrimaryKey(AObject.ClassType);

  if LPrimaryKey = nil then
  begin
    raise EHorseException
                       .New
                       .Error('Não foi encontrada a definição da chave primaria da classe ' + AObject.ClassName)
                       .Title('Sem chave')
                       .Detail('Informe o atributo [PrimaryKey] mo campo chave da classe ' + AObject.ClassName)
                       .&Unit(Self.UnitName)
                       .&Type(TMessageType.Warning)
                       .Code(027)
                       .Status(THTTPStatus.NotAcceptable)
                       .Hint('Method ValidatePrimaryKey');
  end;
end;

end.
