import bcrypt from 'bcrypt';

export const hashPassword = async (plainPassword:string) => {
    const saltRounds = 10; // You can adjust the number of salt rounds
    const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);
    return hashedPassword;
};

export const comparePasswords = async (plainPassword:string, hashedPassword:string) => {
    const isMatch = await bcrypt.compare(plainPassword, hashedPassword);
   
    return isMatch;
};
