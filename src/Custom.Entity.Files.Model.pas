unit Custom.Entity.Files.Model;

interface

uses Custom.Entity.Core.Model, Custom.Entity.Core.Types, Custom.Entity.Core.Attributes;

type
  TEntityFilesModel = class(TEntityCoreModel)
  private
    FFileName    : Nullable<String>;
    FExtension   : Nullable<String>;
    FDataFile    : Nullable<TDateTime>;
    FDataModified: Nullable<TDateTime>;
    FDirectory   : Nullable<String>;
    FVersion     : Nullable<Integer>;
  public
    property FileName : Nullable<String> read FFileName write FFileName;
    property Extension: Nullable<String> read FExtension write FExtension;
    [FormatValue('yyyy-mm-dd hh:mm:ss')]
    property DataFile: Nullable<TDateTime> read FDataFile write FDataFile;
    [FormatValue('yyyy-mm-dd hh:mm:ss')]
    property DataModified: Nullable<TDateTime> read FDataModified write FDataModified;
    property Directory   : Nullable<String> read FDirectory write FDirectory;
    property Version     : Nullable<Integer> read FVersion write FVersion;
  end;

implementation

end.
