unit Custom.Enitty.Core.Service;

interface

uses Horse, Custom.Entity.Core.Controller, System.Rtti, Custom.Entity.Core.Attributes, Web.HTTPApp, System.TypInfo, Horse.Commons,
  System.JSON, {$IFDEF SWAGGER}GBSwagger.Model.Interfaces,{$ENDIF} JOSE.Core.JWT;

type
  IEntityCoreService = interface
    ['{53465F6C-4C4F-4D8F-B376-3010EF222160}']
    procedure Register;
  end;

  TEntityCoreService = class(TInterfacedObject)
  public
    const CRoute = 'api/v1/';
  end;

  TEntityCoreService<T: TEntityCoreController; I: IEntityCoreController> = class(TEntityCoreService, IEntityCoreService)
  strict private
    FClass: TClass;

    function GetEndpointDescription(const AProperty: TRttiProperty): String;
  private
    function GetCallBack: THorseCallback; overload;
    function PutCallBack: THorseCallback; overload;
    function PostCallBack: THorseCallback; overload;
    function DeleteCallBack: THorseCallback; overload;
    function GetRouteDelete: String;
    function GetRoutePut: String;
    function GetEndpointNameDelete: String;
    function GetEndpointNamePut: String;
    function GetParameter(const AMethodType: TMethodType): String;

    procedure Publish(const AProperty: TRttiProperty);

  protected
    procedure Register; virtual;
    procedure GetCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc); overload; virtual;
    procedure PutCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc); overload; virtual;
    procedure PostCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc); overload; virtual;
    procedure DeleteCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc); overload; virtual;
    procedure BeforePut(AParams: THorseList; const ASession: TJWTClaims); virtual;
    procedure BeforeGet(AParams: THorseList; const ASession: TJWTClaims); virtual;
    procedure BeforeDelete(AParams: THorseCoreParam); virtual;
    {$IFDEF SWAGGER}
    procedure MakeSwaggerGet(const AProperty: TRttiProperty); virtual;
    procedure MakeSwaggerPost(const AProperty: TRttiProperty); virtual;
    procedure MakeSwaggerDelete(const AProperty: TRttiProperty); virtual;
    procedure MakeSwaggerPut(const AProperty: TRttiProperty); virtual;
    {$ENDIF}

    function GetRoute: String;
    function GetRouteWithKey: String;
    function GetEndpointName: String;
    function GetEndpointNameWithKey: String;
    function GetEndpointTag: String;
    function GetController: I; overload;
    function GetController(const AParameter: TArray<TValue>): I; overload;
    function GetModelClass: TClass;

    property Get: THorseCallBack read GetCallBack;
    property Put: THorseCallBack read PutCallBack;
    property Post: THorseCallBack read PostCallBack;
    property Delete: THorseCallBack read DeleteCallBack;
  public
    class function New: IEntityCoreService;
  end;

{$IFDEF SWAGGER}
var
  FSwagger: IGBSwagger;
{$ENDIF}

implementation

{ TEntityCoreService }

uses Custom.Entity.Core.Mapper, System.StrUtils, System.SysUtils, {$IFDEF SWAGGER}Horse.GBSwagger,{$ENDIF} Custom.Entity.Core.Server.Helper;

function TEntityCoreService<T, I>.GetCallBack: THorseCallback;
begin
  Result := GetCallBack;
end;

function TEntityCoreService<T, I>.DeleteCallBack: THorseCallback;
begin
  Result := DeleteCallBack;
end;

procedure TEntityCoreService<T, I>.BeforeDelete(AParams: THorseCoreParam);
begin
end;

procedure TEntityCoreService<T, I>.BeforeGet(AParams: THorseList; const ASession: TJWTClaims);
begin
end;

procedure TEntityCoreService<T, I>.BeforePut(AParams: THorseList; const ASession: TJWTClaims);
begin
end;

procedure TEntityCoreService<T, I>.DeleteCallBack(AReq: THorseRequest;ARes: THorseResponse; ANext: TNextProc);
begin
  BeforeDelete(AReq.Params);
end;

procedure TEntityCoreService<T, I>.GetCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
begin
  try
    var LSession := AReq.Session<TJWTClaims>;

    BeforeGet(AReq.Params.Dictionary, LSession);
    var LJsonValue := GetController([LSession]).Get(AReq.Params);

    if (LJsonValue = nil) or (LJsonValue.Null) then
    begin
      LJsonValue.Free;
      ARes.Status(THTTPStatus.NoContent);
    end
    else
    begin
      ARes.Send<TJSONValue>(LJsonValue);
    end;
  except
    on E: EHorseException do
    begin
      ARes.Status(E.Status);
      raise;
    end;
    on E: Exception do
    begin
      ARes.Status(THTTPStatus.BadRequest);
      raise EHorseException
                        .New
                        .Title('Não foi possível buscar os dados')
                        .Error(E.Message)
                        .&Type(TMessageType.Error)
                        .&Unit(Self.UnitName)
                        .Status(THTTPStatus.BadRequest)
                        .Code(011);
    end;
  end;
end;

function TEntityCoreService<T, I>.GetController(const AParameter: TArray<TValue>): I;
begin
  Result := TEntityCoreMapper
                        .GetMethod<T>('Create')
                        .Invoke(TClass(T), [TValue.From(AParameter)])
                        .AsType<I>;
end;

function TEntityCoreService<T, I>.GetController: I;
begin
  Result := GetController(nil);
end;

function TEntityCoreService<T, I>.GetEndpointDescription(const AProperty: TRttiProperty): String;
begin
  Result := String.Empty;

  var LEndpointDiscription := AProperty.GetAttribute<EndpointDescription>;

  if LEndpointDiscription <> nil then
  begin
    Result := LEndpointDiscription.Value.AsString;
  end;
end;

function TEntityCoreService<T, I>.GetEndpointName: String;
begin
  Result := Self.ClassName.Remove(0, 1);

  if Result.Substring(Result.Length - 7).ToUpper.Equals('SERVICE') then
  begin
    Result := Result.Substring(0, Result.Length - 7);
  end;
end;

function TEntityCoreService<T, I>.GetEndpointNameDelete: String;
begin
   Result := GetEndpointNameWithKey;

  if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyDelete>(Self.ClassType) <> nil then
  begin
    Result := GetEndpointName;
  end;
end;

function TEntityCoreService<T, I>.GetEndpointNamePut: String;
begin
  Result := GetEndpointNameWithKey;

  if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyPut>(Self.ClassType) <> nil then
  begin
    Result := GetEndpointName;
  end;
end;

function TEntityCoreService<T, I>.GetEndpointNameWithKey: String;
begin
  Result := GetEndpointName + '/' +
            TEntityCoreMapper
                       .GetPrimaryKey(GetModelClass)
                       .GetParameterEndpoint;
end;

function TEntityCoreService<T, I>.GetEndpointTag: String;
begin
  TEntityCoreMapper
             .GetAttribute<EndpointTag, String>(Self.ClassType,
                                                Result);
end;

function TEntityCoreService<T, I>.GetModelClass: TClass;
begin
  if FClass = nil then
  begin
    FClass := T.ModelClass;
  end;

  Result := FClass;
end;

function TEntityCoreService<T, I>.GetParameter(const AMethodType: TMethodType): String;
begin
  case AMethodType of
    mtPut:
      begin
        if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyDelete>(Self.ClassType) = nil then
        begin
          Result := TEntityCoreMapper.GetPrimaryKey(GetModelClass).Name;
        end;
      end;
    mtDelete:
      if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyPut>(Self.ClassType) = nil then
      begin
        Result := TEntityCoreMapper.GetPrimaryKey(GetModelClass).Name;
      end;
  else
    begin
      Result := TEntityCoreMapper.GetPrimaryKey(GetModelClass).Name;
    end;
  end;
end;

function TEntityCoreService<T, I>.GetRoute: String;
begin
  Result := Concat(CRoute, GetEndpointName);
end;

function TEntityCoreService<T, I>.GetRouteDelete: String;
begin
  Result := GetRouteWithKey;

  if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyDelete>(Self.ClassType) <> nil then
  begin
    Result := GetRoute;
  end;
end;

function TEntityCoreService<T, I>.GetRoutePut: String;
begin
  Result := GetRouteWithKey;

  if TEntityCoreMapper.GetAttribute<NoShowPrimaryKeyPut>(Self.ClassType) <> nil then
  begin
    Result := GetRoute;
  end;
end;

function TEntityCoreService<T, I>.GetRouteWithKey: String;
begin
  Result := GetRoute  + '/:' +
            TEntityCoreMapper
                       .GetPrimaryKey(GetModelClass)
                       .Name;
end;

{$IFDEF SWAGGER}
procedure TEntityCoreService<T, I>.MakeSwaggerDelete(const AProperty: TRttiProperty);
begin
  var LSwaggerDelete :=  FSwagger
                             .Path(GetEndpointNameDelete)
                             .Tag(GetEndpointTag)
                             .DELETE('Excluir ou cancelar um registro',
                                     GetEndpointDescription(AProperty));

  var LParameter := GetParameter(TMethodType.mtDelete);

  if not LParameter.Trim.IsEmpty then
  begin
    LSwaggerDelete := LSwaggerDelete
                               .AddParamQuery(LParameter)
                               .&End
  end;

  LSwaggerDelete
         .AddResponse(Ord(THTTPStatus.OK), 'Registro excluído com sucesso!')
         .Schema(GetModelClass)
         .&End
         .AddParamBody(GetModelClass.ClassName)
         .ParamType(TGBSwaggerParamType.gbBody)
         .Schema(GetModelClass)
         .&End
         .AddResponse(Ord(THTTPStatus.BadRequest), 'Falha na requisição')
         .&End
         .AddResponse(Ord(THTTPStatus.NotFound), 'Endpoint não foi encontrado')
         .&End
         .AddResponse(Ord(THTTPStatus.InternalServerError), 'Erro não tratado no servidor de aplicação')
         .&End
     .&End
  .&End;
end;

procedure TEntityCoreService<T, I>.MakeSwaggerGet(const AProperty: TRttiProperty);
begin
  Fswagger
     .Path(GetEndpointName)
     .Tag(GetEndpointTag)
     .GET('Listar todos os registros',
          GetEndpointDescription(AProperty))
       .AddResponse(Ord(THTTPStatus.OK), 'Consulta realizada com sucesso!')
         .Schema(GetModelClass)
         .IsArray(True)
       .&End
       .AddResponse(Ord(THTTPStatus.NoContent), 'Nenhum registro foi encontrado')
       .&End
       .AddResponse(Ord(THTTPStatus.BadRequest), 'Falha na requisição')
       .&End
       .AddResponse(Ord(THTTPStatus.NotFound), 'Endpoint não foi encontrado')
       .&End
       .AddResponse(Ord(THTTPStatus.InternalServerError), 'Erro não tratado no servidor de aplicação')
       .&End
     .&End
  .&End;
end;

procedure TEntityCoreService<T, I>.MakeSwaggerPost(const AProperty: TRttiProperty);
begin
  Fswagger
     .Path(GetEndpointName)
     .Tag(GetEndpointTag)
     .POST('Adicionar um novo registro',
          GetEndpointDescription(AProperty))
           .AddResponse(Ord(THTTPStatus.OK), 'Registro inserido com sucesso!')
             .Schema(GetModelClass)
         .&End
         .AddParamBody(GetModelClass.ClassName)
           .ParamType(TGBSwaggerParamType.gbBody)
           .Schema(GetModelClass)
         .&End
         .AddResponse(Ord(THTTPStatus.BadRequest), 'Falha na requisição')
         .&End
         .AddResponse(Ord(THTTPStatus.NotFound), 'Endpoint não foi encontrado')
         .&End
         .AddResponse(Ord(THTTPStatus.InternalServerError), 'Erro não tratado no servidor de aplicação')
         .&End
     .&End
  .&End;
end;

procedure TEntityCoreService<T, I>.MakeSwaggerPut(const AProperty: TRttiProperty);
begin
  var LSwaggerPut := Fswagger
                       .Path(GetEndpointNamePut)
                       .Tag(GetEndpointTag)
                       .PUT('Atualizar o registro',
                            GetEndpointDescription(AProperty));

  var LParameter := GetParameter(TMethodType.mtPut);

  if not LParameter.Trim.IsEmpty then
  begin
    LSwaggerPut := LSwaggerPut
                          .AddParamPath(LParameter)
                          .Required(True)
                   .&End;
  end;

  LSwaggerPut
         .AddResponse(Ord(THTTPStatus.OK), 'Registro excluído com sucesso!')
           .Schema('String')
         .&End
         .AddParamBody(GetModelClass.ClassName)
         .ParamType(TGBSwaggerParamType.gbBody)
         .Schema(GetModelClass)
         .&End
         .AddResponse(Ord(THTTPStatus.BadRequest), 'Falha na requisição')
         .&End
         .AddResponse(Ord(THTTPStatus.NotFound), 'Endpoint não foi encontrado')
         .&End
         .AddResponse(Ord(THTTPStatus.InternalServerError), 'Erro não tratado no servidor de aplicação')
         .&End
     .&End
  .&End;
end;

{$ENDIF}

class function TEntityCoreService<T, I>.New: IEntityCoreService;
begin
  Result := Self.Create;
end;

function TEntityCoreService<T, I>.PostCallBack: THorseCallback;
begin
  Result := PostCallBack;
end;

procedure TEntityCoreService<T, I>.PostCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
begin
  try
    var LSession := AReq.Session<TJWTClaims>;

    ARes.Send<TJSONValue>(GetController([LSession]).Post(AReq.Body<TJSONValue>));
  except
    on E: EHorseException do
    begin
      ARes.Status(E.Status);
      raise;
    end;
    on E: Exception do
    begin
      ARes.Status(THTTPStatus.InternalServerError);
      raise EHorseException
                        .New
                        .Title('Erro no endpoint')
                        .Error(E.Message)
                        .Detail('Erro ao tentar consumir o endpoint ' + GetEndpointName + ' no método Post')
                        .&Unit(Self.UnitName)
                        .&Type(TMessageType.Error)
                        .Code(013)
                        .Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TEntityCoreService<T, I>.Publish(const AProperty: TRttiProperty);
begin
  case AnsiIndexStr(AProperty.Name, ['Get', 'Delete', 'Post', 'Put']) of
    0:
    begin
      THorse
          .Route(GetRoute)
          .Get(Get);
      {$IFDEF SWAGGER}MakeSwaggerGet(AProperty){$ENDIF};
    end;
    1:
    begin
      THorse
          .Route(GetRouteDelete)
          .Delete(Delete);
      {$IFDEF SWAGGER}MakeSwaggerDelete(AProperty){$ENDIF};
    end;
    2:
    begin
      THorse
          .Route(GetRoute)
          .Post(Post);
      {$IFDEF SWAGGER}MakeSwaggerPost(AProperty){$ENDIF};
    end;
    3:
    begin
      THorse
          .Route(GetRoutePut)
          .Put(Put);
       {$IFDEF SWAGGER}MakeSwaggerPut(AProperty){$ENDIF};
    end;
  end;
end;

procedure TEntityCoreService<T, I>.PutCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
begin
  try
    var LSession := AReq.Session<TJWTClaims>;

    BeforePut(AReq.Params.Dictionary, LSession);
    GetController([LSession]).Put(AReq.Body<TJSONObject>.Clone as TJSONObject,
                                  AReq.Params.ToArray);

    ARes.Send('Atualização efetuada com sucesso!');
  except
    on E: EHorseException do
    begin
      ARes.Status(E.Status);
      raise;
    end;
    on E: Exception do
    begin
      ARes.Status(THTTPStatus.InternalServerError);
      raise EHorseException
                        .New
                        .Title('Erro no endpoint')
                        .Error(E.Message)
                        .Detail('Erro ao tentar consumir o endpoint ' + GetEndpointName + ' no método Put')
                        .&Unit(Self.UnitName)
                        .&Type(TMessageType.Error)
                        .Code(032)
                        .Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

function TEntityCoreService<T, I>.PutCallBack: THorseCallback;
begin
  Result := PutCallBack;
end;

procedure TEntityCoreService<T, I>.Register;
begin
  var LProperties := TEntityCoreMapper.GetProperties(Self.ClassType);

  for var LProperty in LProperties do
  begin
    Publish(LProperty);
  end;
end;

initialization
   {$IFDEF SWAGGER}
   FSwagger := Swagger.BasePath(TEntityCoreService.CRoute);
   {$ENDIF}

end.
