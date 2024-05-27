unit Custom.Entity.Core.Controller;

interface

uses Custom.Entity.Core.Business, System.JSON, System.Rtti,
  Custom.Entity.Core.Model, System.Generics.Collections, Horse;

type
  IEntityCoreController = interface
    ['{800FBFC8-AA2F-4D7B-B0E4-229C4EF487DD}']
    function Get(const AParams: THorseCoreParam ): TJsonValue; overload;
    function Post(const AJsonObject: TJsonValue): TJsonValue;
    procedure Put(const AJsonObject: TJsonValue; const AParams: TArray <TPair< String, String>>);
  end;

  TEntityCoreController = class(TInterfacedObject, IEntityCoreController)
  protected
    function Get(const AParams: THorseCoreParam): TJsonValue; overload; virtual; abstract;
    function Post(const AJsonObject: TJsonValue): TJsonValue; virtual; abstract;
    procedure Put(const AJsonObject: TJsonValue; const AParams: TArray <TPair< String, String>>); virtual; abstract;
  public
    class function ModelClass: TEntityCoreModelClass; virtual;
  end;

  TEntityCoreController<T: TEntityCoreBusiness; I: IEntityCoreBusiness> = class(TEntityCoreController)
  protected
    Business  : I;
    FParameter: TArray<TValue>;

    function Get(const AParams: THorseCoreParam): TJsonValue; override;
    function Post(const AJsonObject: TJsonValue): TJsonValue; override;
    procedure Put(const AJsonObject: TJsonValue; const AParams: TArray <TPair< String, String>>); override;
  public
    class function ModelClass: TEntityCoreModelClass; override;

    constructor Create(const AParameter: TArray<TValue>); overload; virtual;
  end;

implementation

{ TEntityCoreController<T, I> }

uses Custom.Entity.Core.Mapper, System.SysUtils, Custom.Entity.Core.JSON;

constructor TEntityCoreController<T, I>.Create(const AParameter: TArray<TValue>);
begin
  inherited Create;
  Business := TEntityCoreMapper
                           .GetMethod<T>('Create')
                           .Invoke(TClass(T), [TValue.From(AParameter)])
                           .AsType<I>;
end;

class function TEntityCoreController<T, I>.ModelCLass: TEntityCoreModelClass;
begin
  inherited;
  Result := T.ModelClass;
end;

function TEntityCoreController<T, I>.Post(const AJsonObject: TJsonValue): TJsonValue;
begin
  Result := AJsonObject;

  try
  if AJsonObject is TJSONObject then
  begin
    Result := TEntityCoreJSON.ToJsonObject(Business.Post(AJsonObject.AsType<TJSONObject>));
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
                         .Title('Erro ao efetuar o Pos!')
                         .Status(THTTPStatus.BadRequest)
                         .Error(E.Message)
                         .&Type(TMessageType.Error)
                         .Detail('Erro ao retorno o json com os registros do post')
                         .&Unit(UnitName)
                         .Code(002)
                         .Hint('método Post');
    end;
  end;
end;

procedure TEntityCoreController<T, I>.Put(const AJsonObject: TJsonValue; const AParams: TArray<TPair<String, String>>);
begin
  try
    if AJsonObject is TJSONObject then
    begin
      Business.Put(AJsonObject.AsType<TJSONObject>, AParams);
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
                         .Title('Erro ao efetuar o Put!')
                         .Status(THTTPStatus.BadRequest)
                         .Error(E.Message)
                         .&Type(TMessageType.Error)
                         .Detail('Erro ao tentar atualizar o registro')
                         .&Unit(UnitName)
                         .Code(031)
                         .Hint('método Put');
    end;
  end;
end;

function TEntityCoreController<T, I>.Get(const AParams: THorseCoreParam): TJsonValue;
begin
  try
    if AParams.Count > 0 then
    begin
      Result := Business.Get(AParams);
    end
    else
    begin
      Result := Business.Get;
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
                     .Code(002)
                     .Hint('método Get');
  end;
end;
end;

{ TEntityCoreController }

class function TEntityCoreController.ModelClass: TEntityCoreModelClass;
begin
  Result := nil;
end;

end.
