# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "rails_helper"

RSpec.describe "CourseClassProfessorEscalation", type: :request do
  before(:all) do
    @professor_1 = FactoryBot.create(:professor, name: "Professor 1")
    @professor_2 = FactoryBot.create(:professor, name: "Professor 2")
    @professor_3 = FactoryBot.create(:professor, name: "Professor 3")
    @student = FactoryBot.create(:student, name: "Aluno")

    @professor1_user = FactoryBot.create(:user, :professor,
      email: "professor1@example.com",
      professor: @professor_1
    )

    @professor2_user = FactoryBot.create(:user, :professor,
      email: "professor2@example.com",
      professor: @professor_2
    )

    @student_user = FactoryBot.create(:user, :student,
      email: "aluno@example.com",
      student: @student
    )
    @coordinator_user = FactoryBot.create(:user, :coordination,
      email: "coordenador@example.com",
    )

    [@professor1_user, @professor2_user, @student_user, @coordinator_user].each do |user|
      user.skip_confirmation!
      user.save!
    end
    @student_user.update!(actual_role: Role::ROLE_ALUNO)
  end

  before(:each) do
    course_type = FactoryBot.create(:course_type, has_score: true)
    course = FactoryBot.create(:course, course_type: course_type)
    @course_class = FactoryBot.create(
      :course_class,
      course: course,
      professors: [@professor_1, @professor_2],
      year: YearSemester.current.year,
      semester: YearSemester.current.semester
    )

    CustomVariable.create!(
        variable: "professor_login_can_post_grades", value: "yes_all_semesters"
      )
  end

  describe "authenticated access" do
    it "allows a signed-in professor to access profile editing" do
      sign_in @professor1_user

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@professor1_user.email)
    end

    it "allows a signed-in student to access profile editing" do
      sign_in @student_user

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@student_user.email)
    end

    it "allows a signed-in coordinator to access profile editing" do
      sign_in @coordinator_user

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@coordinator_user.email)
    end
  end

  describe "base information" do
    it "course classes path is accessible" do
      course_class = FactoryBot.create(
        :course_class,
        professors: [@professor_1],
        year: YearSemester.current.year,
        semester: YearSemester.current.semester
      )
      expect(course_class_path(course_class))
        .to eq("/course_classes/#{course_class.id}")
    end

    it "course classes edit path is accessible" do
      course_class = FactoryBot.create(
        :course_class,
        professors: [@professor_1],
        year: YearSemester.current.year,
        semester: YearSemester.current.semester
      )
      expect(edit_course_class_path(course_class))
        .to eq("/course_classes/#{course_class.id}/edit")
    end

    it "course class has professor_ids association methods" do
      course_class = FactoryBot.create(
        :course_class,
        professors: [@professor_1],
        year: YearSemester.current.year,
        semester: YearSemester.current.semester
      )

      expect(course_class).to respond_to(:professor_ids)
      expect(course_class).to respond_to(:professor_ids=)
      expect(course_class.professor_ids).to contain_exactly(@professor_1.id)
    end
  end

  describe "changing professors field of a course class" do
    context "when a coordinator is signed in" do
      before(:each) do
        sign_in @coordinator_user
        @coordinator_user.update!(actual_role: Role::ROLE_COORDENACAO)
      end
      it "allows a coordinator to add a professor" do
        # Add another professor to the course class
        expect(@course_class.reload.professors.count).to eq(2)
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_2.id, @professor_3.id]
          }
        }
        expect(@course_class.reload.professors.count).to eq(3)
        # Assert that both professors are now associated with the course class
        expect(response).to have_http_status(:redirect)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2, @professor_3)
      end

      it "allows a coordinator to change a professor" do
        # Change the professor to another professor
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_3.id]
          }
        }
        # Assert that the professor was changed
        expect(response).to have_http_status(:redirect)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_3)
      end

      it "allows a coordinator to remove a professor" do
        # Remove the second professor from the course class
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id]
          }
        }
        # Assert that the second professor was removed
        expect(response).to have_http_status(:redirect)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1)
      end
    end

    context "when a professor is signed in" do
      before(:each) do
        sign_in @professor1_user
        @professor1_user.update!(actual_role: Role::ROLE_PROFESSOR)
      end
      it "does not allow a professor to add another professor" do
        # Try to add another professor to the course class
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_2.id, @professor_3.id]
          }
        }
        # Assert that the second professor was not added
        expect(response).to have_http_status(:ok)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end

      it "does not allow a professor to change another professor" do
        # Try to change the professor to another professor
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_3.id]
          }
        }
        # Assert that the professor was not changed
        expect(response).to have_http_status(:ok)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end

      it "does not allow a professor to remove another professor" do
        # Try to remove the second professor from the course class
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id]
          }
        }
        # Assert that the second professor was not removed
        expect(response).to have_http_status(:ok)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end
    end

    context "when a student is signed in" do
      before(:each) do
        sign_in @student_user
        @student_user.update!(actual_role: Role::ROLE_ALUNO)
      end
      it "does not allow a student to add a professor" do
        # Try to add another professor to the course class
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_2.id, @professor_3.id]
          }
        }
        # Assert that the second professor was not added
        expect(response).to have_http_status(:internal_server_error)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end

      it "does not allow a student to change a professor" do
        # Try to change the professor to another professor
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id, @professor_3.id]
          }
        }
        # Assert that the professor was not changed
        expect(response).to have_http_status(:internal_server_error)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end

      it "does not allow a student to remove a professor" do
        # Try to remove the second professor from the course class
        patch course_class_path(@course_class), params: {
          record: {
            professors: [@professor_1.id]
          }
        }
        # Assert that the second professor was not removed
        expect(response).to have_http_status(:internal_server_error)
        expect(@course_class.reload.professors).to contain_exactly(@professor_1, @professor_2)
      end
    end
  end

  describe "changing year and semester of a course class" do
    context "when a coordinator is signed in" do
      before(:each) do
        sign_in @coordinator_user
        @coordinator_user.update!(actual_role: Role::ROLE_COORDENACAO)
      end
      it "allows a coordinator to change the year and semester" do
        # Change the year and semester of the course class
        new_year = YearSemester.current.year + 1
        new_semester = YearSemester.current.semester == 1 ? 2 : 1
        patch course_class_path(@course_class), params: {
          record: {
            year: new_year,
            semester: new_semester
          }
        }
        # Assert that the year and semester were changed
        expect(response).to have_http_status(:redirect)
        expect(@course_class.reload.year).to eq(new_year)
        expect(@course_class.reload.semester).to eq(new_semester)
      end
    end

    context "when a professor is signed in" do
      before(:each) do
        sign_in @professor1_user
        @professor1_user.update!(actual_role: Role::ROLE_PROFESSOR)
      end
      it "does not allow a professor to change the year and semester" do
        # Try to change the year and semester of the course class
        new_year = YearSemester.current.year + 1
        new_semester = YearSemester.current.semester == 1 ? 2 : 1
        patch course_class_path(@course_class), params: {
          record: {
            year: new_year,
            semester: new_semester
          }
        }
        # Assert that the year and semester were not changed
        expect(response).to have_http_status(:ok)
        expect(@course_class.reload.year).to eq(YearSemester.current.year)
        expect(@course_class.reload.semester).to eq(YearSemester.current.semester)
      end
    end

    context "when a student is signed in" do
      before(:each) do
        sign_in @student_user
        @student_user.update!(actual_role: Role::ROLE_ALUNO)
      end
      it "does not allow a student to change the year and semester" do
        # Try to change the year and semester of the course class
        new_year = YearSemester.current.year + 1
        new_semester = YearSemester.current.semester == 1 ? 2 : 1
        patch course_class_path(@course_class), params: {
          record: {
            year: new_year,
            semester: new_semester
          }
        }
        # Assert that the year and semester were not changed
        expect(response).to have_http_status(:internal_server_error)
        expect(@course_class.reload.year).to eq(YearSemester.current.year)
        expect(@course_class.reload.semester).to eq(YearSemester.current.semester)
      end
    end
  end

  describe "changing student grade field of a course class" do
    before(:each) do
      @enrollment = FactoryBot.create(:enrollment, student: @student)
      @class_enrollment = FactoryBot.create(
        :class_enrollment,
        course_class: @course_class,
        enrollment: @enrollment,
        situation: ClassEnrollment::REGISTERED
      )

      allow(CustomVariable)
          .to receive(:professor_login_can_post_grades)
          .and_return("yes")

      allow(Notifier).to receive(:send_emails)
    end
    context "when a coordinator is signed in" do
      before(:each) do
        sign_in @coordinator_user
        @coordinator_user.update!(actual_role: Role::ROLE_COORDENACAO)
      end
      it "allows a coordinator to change the student grade" do
        patch course_class_path(@course_class), params: {
          record: {
            class_enrollments: {
              "0" => {},
              "#{@class_enrollment.id}" => {
                enrollment: @enrollment.id,
                situation: ClassEnrollment::APPROVED,
                grade: "8.5",
                obs: "Good performance",
                disapproved_by_absence: 0,
                grade_not_count_in_gpr: 0,
                justification_grade_not_count_in_gpr: "",
                id: @class_enrollment.id
              }
            }
          }
        }
        # Assert that the grade was changed
        expect(response).to have_http_status(:redirect)
        expect(@class_enrollment.reload.grade).to eq(85)
        expect(@class_enrollment.reload.situation).to eq(ClassEnrollment::APPROVED)
      end
    end

    context "when a professor is signed in" do
      it "allows professor 1 to change the student grade" do
        sign_in @professor1_user
        @professor1_user.update!(actual_role: Role::ROLE_PROFESSOR)

        patch course_class_path(@course_class), params: {
          record: {
            class_enrollments: {
              "0" => {},
              "#{@class_enrollment.id}" => {
                enrollment: @enrollment.id,
                situation: ClassEnrollment::APPROVED,
                grade: "8.5",
                obs: "Good performance",
                disapproved_by_absence: 0,
                grade_not_count_in_gpr: 0,
                justification_grade_not_count_in_gpr: "",
                id: @class_enrollment.id
              }
            }
          }
        }
        # Assert that the grade was changed
        expect(response).to have_http_status(:redirect)
        expect(@class_enrollment.reload.grade).to eq(85)
        expect(@class_enrollment.reload.situation).to eq(ClassEnrollment::APPROVED)
      end

      it "allows professor 2 to change the student grade" do
        sign_in @professor2_user
        @professor2_user.update!(actual_role: Role::ROLE_PROFESSOR)

        patch course_class_path(@course_class), params: {
          record: {
            class_enrollments: {
              "0" => {},
              "#{@class_enrollment.id}" => {
                enrollment: @enrollment.id,
                situation: ClassEnrollment::APPROVED,
                grade: "8.5",
                obs: "Good performance",
                disapproved_by_absence: 0,
                grade_not_count_in_gpr: 0,
                justification_grade_not_count_in_gpr: "",
                id: @class_enrollment.id
              }
            }
          }
        }
        # Assert that the grade was changed
        expect(response).to have_http_status(:redirect)
        expect(@class_enrollment.reload.grade).to eq(85)
        expect(@class_enrollment.reload.situation).to eq(ClassEnrollment::APPROVED)
      end
    end

    context "when a student is signed in" do
      before(:each) do
        sign_in @student_user
        @student_user.update!(actual_role: Role::ROLE_ALUNO)
      end
      it "does not allow a student to change the student grade" do
        patch course_class_path(@course_class), params: {
          record: {
            class_enrollments: {
              "0" => {},
              "#{@class_enrollment.id}" => {
                enrollment: @enrollment.id,
                situation: ClassEnrollment::APPROVED,
                grade: "8.5",
                obs: "Good performance",
                disapproved_by_absence: 0,
                grade_not_count_in_gpr: 0,
                justification_grade_not_count_in_gpr: "",
                id: @class_enrollment.id
              }
            }
          }
        }
        # Assert that the grade was changed
        expect(response).not_to have_http_status(:redirect)
        expect(@class_enrollment.reload.grade).to eq(nil)
        expect(@class_enrollment.reload.situation).to eq(ClassEnrollment::REGISTERED)
      end
    end
  end

  describe "CourseClass: professor não reescreve a lista de professores" do
    before(:each) do
      sign_in @professor1_user
      @professor1_user.update!(actual_role: Role::ROLE_PROFESSOR)

      CustomVariable.create!(
        variable: "professor_login_can_post_grades", value: "yes_all_semesters"
      )
    end

    it "controle: o formulário de edição não oferece o campo de professores" do
      get edit_course_class_path(@course_class)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@professor_1.name)
      expect(response.body).not_to match(/name="record\[professors\]/)
    end

    it "controle: mudar uma coluna pelo mesmo caminho é barrado" do
      put course_class_path(@course_class), params: { record: { year: "2022" } }
      expect(@course_class.reload.year).to eq(YearSemester.current.year)
    end

    it "não adiciona professor à turma por parâmetro forjado" do
      put course_class_path(@course_class), params: {
        record: { professors: [@professor_1.id.to_s, @professor_2.id.to_s, @professor_3.id.to_s] }
      }
      expect(@course_class.reload.professors.map(&:id)).to eq([@professor_1.id, @professor_2.id]),
        "professores agora são #{@course_class.reload.professors.map(&:name).inspect}"
    end

    it "não remove professor da turma por parâmetro forjado" do
      @course_class.professors = [@professor_1, @professor_2]
      @course_class.save!
      put course_class_path(@course_class), params: {
        record: { professors: [@professor_1.id.to_s] }
      }
      expect(@course_class.reload.professors.map(&:id)).to include(@professor_2.id),
        "colega removido; sobraram #{@course_class.reload.professors.map(&:name).inspect}"
    end
  end
end
