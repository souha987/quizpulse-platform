import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  statusCode: number;
  constructor(message: string, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export const notFoundHandler = (req: Request, res: Response): void => {
  res.status(404).json({
    error: `Route non trouvée : ${req.method} ${req.originalUrl}`,
  });
};

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void => {
  const statusCode = err instanceof AppError ? err.statusCode : 500;
  const message = err.message || 'Une erreur interne est survenue sur le serveur';

  if (process.env.NODE_ENV !== 'test') {
    console.error(`[ERREUR] ${req.method} ${req.url} - ${message}`, err.stack);
  }

  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

