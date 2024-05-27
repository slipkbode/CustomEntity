unit Custom.Entity.Core.Authorization.Service;

interface

uses Horse, Horse.JWT;

type
  IEntityCoreAuthorizationService = interface
    ['{B73677ED-2430-4C22-A9B2-E54404045EF5}']
    function MethodAuthentication(const ACallBack: THorseCallBack): IEntityCoreAuthorizationService; overload;
    function MethodAuthentication: THorseCallBack; overload;
    procedure Register;
  end;

  TEntityCoreAuthorizationService = class(TInterfacedObject, IEntityCoreAuthorizationService)
  strict private
    FCallBack                                : THorseCallBack;
    class var FEntityCoreAuthorizationService: IEntityCoreAuthorizationService;
  private
    function MethodAuthentication(const ACallBack: THorseCallBack): IEntityCoreAuthorizationService; overload;
    function MethodAuthentication: THorseCallBack; overload;
    procedure Register;
  public
    class function New: IEntityCoreAuthorizationService;
  end;


implementation

{ TEntityCoreAuthorizationService }

function TEntityCoreAuthorizationService.MethodAuthentication(const ACallBack: THorseCallBack): IEntityCoreAuthorizationService;
begin
  FCallBack := ACallBack;
end;

function TEntityCoreAuthorizationService.MethodAuthentication: THorseCallBack;
begin
  Result := procedure(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc)
            begin
              var LHorseJWT := HorseJWT('sercurity_service', THorseJWTConfig
                                                                          .New
                                                                          .SkipRoutes(['/swagger/doc/html',
                                                                                       '/swagger/doc/json',
                                                                                       '/api/v1/AtualizarToken']));
              LHorseJWT(AReq, ARes, ANext);

              if Assigned(FCallBack) then
              begin
                FCallBack(AReq, ARes, ANext);
              end;
            end;
end;

class function TEntityCoreAuthorizationService.New: IEntityCoreAuthorizationService;
begin
  if FEntityCoreAuthorizationService = nil then
    FEntityCoreAuthorizationService := TEntityCoreAuthorizationService.Create;

  Result := FEntityCoreAuthorizationService;
end;

procedure TEntityCoreAuthorizationService.Register;
begin
  THorse
     .Post('authorization', FCallBack);
end;

end.
