unit Custom.Entity.Files.Service;

interface

uses Custom.Enitty.Core.Service, Custom.Entity.Files.Controller, Custom.Entity.Core.Attributes,
  Horse, System.Rtti, Web.HTTPApp, System.Classes;

type
  IEntityFilesService = interface(IEntityCoreService)
    ['{9D8EA282-AF1C-4392-9F4E-6D9D95493FD3}']
  end;

  [EndpointTag('Files')]
  [EndpointDescription('Local para ser amazenados arquivos como .exe, .pdf e etc para que o usuário consumir a API')]
  TEntityFilesService = class(TEntityCoreService<TEntityFilesController, IEntityFilesController>, IEntityFilesService)
  protected
    procedure GetCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc); override;
    procedure MakeSwaggerGet(const AProperty: TRttiProperty); override;
  public
    property Get;
  end;

implementation

uses
  System.SysUtils;

var
  FEntity: IEntityFilesService;

{ TEntityFilesService }

procedure TEntityFilesService.GetCallBack(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
begin
  if AReq.Query.Count = 0 then
  begin
    inherited;
  end
  else
  begin
    var LFileName : TFileStream := nil;
    try
      try
        var LController := GetController;
        LFileName := LController.Get(AReq.Query.Field('file').AsString,
                                     AReq.Query.Field('directory').AsString);

        ARes.SendFile(LFileName, AReq.Query.Field('file').AsString, 'application/octet-stream');
      except
        on E: EHorseException do
        begin
          raise;
        end;

        on E: Exception do
        begin
          raise EHorseException
                            .New
                            .Title('Ops... Algo aconteceu')
                            .Error('Não foi possível enviar o arquivo para download. Verifique o detalhe da mensagem')
                            .Detail(E.Message)
                            .Status(THTTPStatus.InternalServerError)
                            .Code(063)
                            .Hint('Method GetCallBack')
                            .&Unit(Self.UnitName);
        end;
      end;
    finally
      LFileName.Free;
    end;
  end;
end;

procedure TEntityFilesService.MakeSwaggerGet(const AProperty: TRttiProperty);
begin
  inherited;
  var LPath := FSwagger.FindPath(GetEndpointName);

  if LPath <> nil then
  begin
    var LMethod := LPath.FindMethod(TMethodType.mtGet);

    if LMethod <> nil then
    begin
      LMethod
          .AddParamQuery('file')
            .Required(False)
            .Schema('string')
          .&End
          .AddParamQuery('directory')
            .Required(False)
            .Schema('string')
          .&End
    end;
  end;
end;

initialization

FEntity := TEntityFilesService.New as IEntityFilesService;
FEntity.Register;

end.
