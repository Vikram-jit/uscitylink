// MariaDB stores JSON columns as LONGTEXT, so Sequelize returns them as strings there
// (MySQL returns parsed values). This getter makes both behave the same.
export const jsonGetter = (name: string) =>
  function (this: any) {
    const value = this.getDataValue(name);
    if (typeof value === "string") {
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    }
    return value;
  };
