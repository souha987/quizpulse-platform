import { Response, NextFunction } from 'express';
import { classService } from '../services/class.service';
import { AuthenticatedRequest } from '../types';

export class ClassController {
  async createClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { nom } = req.body;
      const classe = await classService.createClass(nom, req.user!.userId);
      res.status(201).json(classe);
    } catch (error) {
      next(error);
    }
  }

  async getMyTeacherClasses(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const classes = await classService.getTeacherClasses(req.user!.userId);
      res.status(200).json(classes);
    } catch (error) {
      next(error);
    }
  }

  async getClassDetails(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const classe = await classService.getClassDetails(req.params.id as string, req.user!.userId, req.user!.role);
      res.status(200).json(classe);
    } catch (error) {
      next(error);
    }
  }

  async joinClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { codeClasse } = req.body;
      const result = await classService.joinClass(codeClasse, req.user!.userId);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async leaveClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await classService.leaveClass(id as string, req.user!.userId);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getMyStudentClasses(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const classes = await classService.getStudentClasses(req.user!.userId);
      res.status(200).json(classes);
    } catch (error) {
      next(error);
    }
  }

  async removeStudentFromClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { id, studentId } = req.params;
      const result = await classService.removeStudentFromClass(
        id as string,
        studentId as string,
        req.user!.userId,
        req.user!.role
      );
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { nom } = req.body;
      const updated = await classService.updateClass(
        req.params.id as string,
        nom,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  }

  async deleteClass(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await classService.deleteClass(
        req.params.id as string,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const classController = new ClassController();
