unit Custom.Entity.Files.Controller;

interface

uses Custom.Entity.Core.Controller, Custom.Entity.Files.Business,
  System.Classes;

type
  IEntityFilesController = interface(IEntityCoreController)
    ['{4908F964-7A39-4A9F-83E1-9939F438A519}']
    function Get(const AFileName, ADirectory: String): TFileStream; overload;
  end;

  TEntityFilesController = class(TEntityCoreController<TEntityFilesBusiness, IEntityFilesBusiness>, IEntityFilesController)
  private
    function Get(const AFileName, ADirectory: String): TFileStream; overload;
  end;

implementation

{ TEntityFilesController }

function TEntityFilesController.Get(const AFileName, ADirectory: String): TFileStream;
begin
  Result := Business.Get(AFileName, ADirectory);
end;

end.
