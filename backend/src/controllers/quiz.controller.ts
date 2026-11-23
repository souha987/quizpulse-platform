import { Response, NextFunction } from 'express';
import { quizService } from '../services/quiz.service';
import { AuthenticatedRequest } from '../types';

export class QuizController {
  async createQuiz(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const quiz = await quizService.createQuiz(req.body, req.user!.userId);
      res.status(201).json(quiz);
    } catch (error) {
      next(error);
    }
  }

  async getMyTeacherQuizzes(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const quizzes = await quizService.getTeacherQuizzes(req.user!.userId);
      res.status(200).json(quizzes);
    } catch (error) {
      next(error);
    }
  }

  async getMyAssignedQuizzes(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const quizzes = await quizService.getStudentAssignedQuizzes(req.user!.userId);
      res.status(200).json(quizzes);
    } catch (error) {
      next(error);
    }
  }

  async getQuizById(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const quiz = await quizService.getQuizById(req.params.id as string, req.user?.userId, req.user?.role);
      res.status(200).json(quiz);
    } catch (error) {
      next(error);
    }
  }

  async updateQuiz(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const updated = await quizService.updateQuiz(
        req.params.id as string,
        req.body,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json(updated);
    } catch (error) {
      next(error);
    }
  }

  async deleteQuiz(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      await quizService.deleteQuiz(req.params.id as string, req.user!.userId, req.user?.role);
      res.status(200).json({ message: 'Quiz supprimé avec succès' });
    } catch (error) {
      next(error);
    }
  }

  async duplicateQuiz(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const duplicated = await quizService.duplicateQuiz(
        req.params.id as string,
        req.user!.userId,
        req.user?.role
      );
      res.status(201).json(duplicated);
    } catch (error) {
      next(error);
    }
  }

  async addQuestion(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const question = await quizService.addQuestion(
        req.params.id as string,
        req.body,
        req.user!.userId,
        req.user?.role
      );
      res.status(201).json(question);
    } catch (error) {
      next(error);
    }
  }

  async updateQuestion(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const question = await quizService.updateQuestion(
        req.params.id as string,
        req.params.questionId as string,
        req.body,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json(question);
    } catch (error) {
      next(error);
    }
  }

  async deleteQuestion(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      await quizService.deleteQuestion(
        req.params.id as string,
        req.params.questionId as string,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json({ message: 'Question supprimée avec succès' });
    } catch (error) {
      next(error);
    }
  }

  async reorderQuestions(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      await quizService.reorderQuestions(
        req.params.id as string,
        req.body.questions,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json({ message: 'Questions réorganisées avec succès' });
    } catch (error) {
      next(error);
    }
  }

  async findByPin(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const pin = req.params.pin as string;
      const quiz = await quizService.findByPin(pin);
      res.status(200).json(quiz);
    } catch (error) {
      next(error);
    }
  }
}

export const quizController = new QuizController();
