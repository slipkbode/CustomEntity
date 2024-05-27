unit Custom.Entity.Core.Linq.Constant;

interface

type
  TEntityLinqConstat = packed record
  public const
    cWhere      = 'where %s' + #13;
    cFrom       = 'from %s' + #13;
    cJoin       = 'join %s on (%s)' + #13;
    cLeftJoin   = 'left join %s on (%s)' + #13;
    cSelectAll  = 'select *' + #13;
    cSelect     = 'select %s' + #13;
    cOrderBy    = 'order by %s';
    cGroupBy    = 'group by %s';
    cAnd        = 'and %s' + #13;
    cSelectJson = '%s for json path';
  end;

implementation

end.
