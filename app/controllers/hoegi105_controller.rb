class Hoegi105Controller < ApplicationController
    
    def mainpage
        if current_user.email == "hoegi105@gmail.com"
            redirect_to '/hoegi105/admin'
        else 
            
        end
        if user_signed_in?
            @useremail = current_user.email
            @usered_major = current_user.user_major
            # usered_major == nil 일 때는 아무 강의도 표시하지 않게 
            # User에 저장할 학과 선택
            unless @usered_major == nil
                # 선택한 학과가 없을 경우 저장된 학과의 강의 출력
                if params[:major] == nil
                    @lecture = ClassofhotsMajor.where(:major_id => @usered_major)
                # 선택한 학과가 있을 경우 그 학과의 강의를 출력
        	    elsif  params[:major] != nil
                    @lecture = ClassofhotsMajor.where(:major_id => params[:major])
                end
            else
                #진짜 방법이 없다면 Dummy 학과를 하나 만들어서 강의를 안집어넣는 방법
                #이걸로 작동함
                @lecture = ClassofhotsMajor.where(:major_id => "trash1")
            end
        else
             redirect_to ''
        end
    end
    
    def search
        @lecture = Classofhot.where("lecture_title LIKE ?", "%" + params[:title] + "%")
    end
    
    def major_process
        urmajor = User.find(current_user.id) #Classofhot(DB)에서 특정 id값에 해당하는 자료
        urmajor.user_major = params[:major_choice]
        urmajor.save #받은 값을 lecture에 저장한다.
        
        redirect_to "/hoegi105/mainpage"
    end

    def myreview
        if user_signed_in?
            @lecture = Review.where({ review_writer: current_user.email })
        else
            redirect_to ''
        end
    end
    
    def admin
        unless current_user.email == "hoegi105@gmail.com"
            redirect_to ''
        end
    end
    
    def admin_process
        major_codes = params[:lecturemajor]
        unless user_signed_in?
	        redirect_to ''
        end
        lecture = Classofhot.new #lecture변수는 Classofhot(DB)에 새로운 값을 생성한다.
        lecture.lecture_title = params[:lecturetitle] #lecture_title엔 lecturetitle에 입력된 값을 받는다.
        lecture.professor_name = params[:professorname] #professor_name엔 professorname에 입력된 값을 받는다.
        lecture.typeof_lecture = params[:typeoflecture] #typeof_lecture엔 typeoflecture에 입력된 값을 받는다.
        lecture.typeof_hospi = params[:typeofhospi]
        lecture.save #받은 값을 lecture에 저장한다.
        
        major_codes.each do |major_code|
            lecture_major = ClassofhotsMajor.new
            lecture_major.classofhot_id = lecture.id
            lecture_major.major_id = Major.where('major_code = ?', major_code).take.id
            lecture_major.save
        end
        
        redirect_to :back #mainpage로 이동
    end
    
    def admin_update
        unless user_signed_in?
	        redirect_to ''
        end
        @lecture = Classofhot.find(params[:id])
    end
    
    def admin_update_process
        major_codes = params[:lecturemajor]
        unless user_signed_in?
	        redirect_to ''
        end
        lecture = Classofhot.find(params[:id]) #Classofhot(DB)에서 특정 id값에 해당하는 자료
        lecture.lecture_title = params[:lecturetitle] #lecture_title엔 lecturetitle에 입력된 값을 받는다.
        lecture.professor_name = params[:professorname] #professor_name엔 professorname에 입력된 값을 받는다.
        lecture.typeof_lecture = params[:typeoflecture] #typeof_lecture엔 typeoflecture에 입력된 값을 받는다.
        lecture.typeof_hospi = params[:typeofhospi]
        lecture.save #받은 값을 lecture에 저장한다.
        
        major_codes.each do |major_code|
            # 수정요함!
            lecture_major = ClassofhotsMajor.new
            lecture_major.classofhot_id = lecture.id
            lecture_major.major_id = Major.where('major_code = ?', major_code).take.id
            lecture_major.save
        end
        redirect_to '/hoegi105/mainpage' #mainpage로 이동
    end

    
    def admin_delete
        unless current_user.email == "hoegi105@gmail.com"
            redirect_to ''
        end
        lecture = Classofhot.find(params[:id]) #Classofhot(DB)에서 특정 id값에 해당하는 자료
        lecture.reviews.destroy_all
        lecture.destroy #해당 lecture을 삭제한다.
        redirect_to :back #위 과정을 마치고 board 뷰페이지로 이동한다.
    end
    
    def classreview
        if user_signed_in?
            @useremail = current_user.email
            @lecture = Classofhot.find(params[:id]) #변수 lecture는 Classofhot(db)의 특정 id를 받은 값과 같다.
            @mylecturerevw = Review.find_by(:classofhot_id => params[:id], :review_writer => @useremail)
            if Review.where.not(eval_star: nil).exists?(:classofhot_id => params[:id], :review_writer => @useremail, :review_content => nil)
                @mycontent = Review.find_by(:classofhot_id => params[:id], :review_writer => @useremail).eval_star
                @mycontent_id = Review.find_by(:classofhot_id => params[:id], :review_writer => @useremail).id
            end
            # 평점의 평균값 도출!
            sumofrvwsG = @lecture.reviews.all.sum :eval_star
            if sumofrvwsG == 0
                @averagecomft_grade = 0.to_i
            else
                @averagecomft_grade = sumofrvwsG / @lecture.reviews.count
            end
            
            # 학점 잘 주니
            sumofgrade = @lecture.reviews.all.sum :eval_grade
            if sumofgrade == 0
                @representgrade = nil
            else
                @representgrade = sumofgrade / @lecture.reviews.count
            end
            # 편한하니
            sumofeasy = @lecture.reviews.all.sum :eval_easy
            if sumofeasy == 0
                @representeasy = nil
            else
                @representeasy = sumofeasy / @lecture.reviews.count
            end
            # 배우는게 있니
            sumofacademic = @lecture.reviews.all.sum :eval_academic
            if sumofacademic == 0
                @representacademic = nil
            else
                @representacademic = sumofacademic / @lecture.reviews.count
            end
        else
            redirect_to ''
        end
        
        m = Classofhot.find(params[:id])
        @major = m.majors
        
    end
    
    def review_process
        if user_signed_in?
            @useremail = current_user.email
	        if Review.exists?(:classofhot_id => params[:id], :review_writer => @useremail)
	            redirect_to '/hoegi105/error'
            else
                @profile = ["거북왕", "고라파덕", "꼬부기", "롱스톤", "리자드", "리자몽", 
                            "어니부기", "나옹", "이상해꽃", "피카츄", "이상해씨", "이상해풀", 
                            "디그다", "토게피", "파이리", "푸린", "", "꼬마돌", "뮤", "발챙이",
                            "성원숭", "야돈", "잉어킹"]
                lecturereviews = Review.where('classofhot_id = ?',params[:id])
                lecturereview = Review.new #lecturereview변수는 Review(DB)에 새로운 값을 생성한다.
                lecturereview.classofhot_id = params[:id] #널 내가 빼먹었었구나! 시발@
                lecturereview.review_content = params[:reviewcontent] #review_content엔 reviewcontent에 입력된 값을 받는다.
                lecturereview.review_writer = @useremail #review_writer엔 reviewwriter에 입력된 값을 받는다.
                lecturereview.eval_star = params[:stareval]
                lecturereview.eval_grade = params[:grade] #eval_comft엔 evalcomft에 입력된 값을 받는다.
                lecturereview.eval_easy = params[:easy] #eval_comft엔 evalcomft에 입력된 값을 받는다.
                lecturereview.eval_academic = params[:academic] #eval_comft엔 evalcomft에 입력된 값을 받는다.
                
            # 강의리뷰에 이미지 이름을 넣는 로직
                userpicture = []
                lecturereviews.each do |lecture|
                     userpicture << lecture.picture
                end
                picture = @profile.sample
                while userpicture.include? picture
                    @profile.delete(picture)
                    picture = @profile.sample
                    if @profile.count == 0
                        picture = '리뷰왕'
                        break
                    end
                end
                lecturereview.picture = picture
                
                lecturereview._like = 0
                lecturereview._dislike = 0
                lecturereview.save #받은 값을 lecturereview에 저장한다.
                redirect_to :back
            end
        else
	        redirect_to ''
        end
    end
    
    def edit_review
        unless user_signed_in?
	        redirect_to ''
        end
        @useremail = current_user.email
        lecturereview = Review.find(params[:id])
        lecturereview.review_writer = @useremail #review_writer엔 reviewwriter에 입력된 값을 받는다.
        lecturereview.eval_star = params[:stareval]
        lecturereview.review_content = params[:reviewcontent] 
        lecturereview.eval_grade = params[:grade] #eval_comft엔 evalcomft에 입력된 값을 받는다.
        lecturereview.eval_easy = params[:easy] #eval_comft엔 evalcomft에 입력된 값을 받는다.
        lecturereview.eval_academic = params[:academic] #eval_comft엔 evalcomft에 입력된 값을 받는다.
        lecturereview.save
        redirect_to :back
    end
    
    def reply
        unless user_signed_in?
	        redirect_to ''
        end
        @review = Review.find(params[:id]) #변수 lecture는 Classofhot(db)의 특정 id를 받은 값과 같다.
    end
    
    def reply_process
        if user_signed_in?
	        useremail = current_user.email
	    else
	        redirect_to ''
        end
        replyinreview = Reply.new #replyinreview변수는 Review(DB)에 새로운 값을 생성한다.
        replyinreview.review_id = params[:id]
        replyinreview.reply_content = params[:replycontent] #review_content엔 reviewcontent에 입력된 값을 받는다.
        replyinreview.reply_writer = useremail #review_writer엔 reviewwriter에 입력된 값을 받는다.
        replyinreview.save #받은 값을 replyinreview에 저장한다.
        redirect_to :back
    end
    
    # def review_delete
    #     useremail = current_user.email
    #     review = Review.find(params[:id])
    #     if useremail != review.review_writer
    #         redirect_to :back
    #     else
    #         review.destroy #해당 article을 삭제한다.
    #         redirect_to :back #위 과정을 마치고 board 뷰페이지로 이동한다.
    #     end
    # end
    
    def like
        if user_signed_in?
	        useremail = current_user.email
	    else
	        redirect_to ''
        end
        
        # 악성이용자 근절을 위한 수정 요함
        if Proscon.exists?(:review_id => params[:id], :agree_user => current_user.email)
            redirect_to '/hoegi105/error'
        elsif Proscon.exists?(:review_id => params[:id], :disagree_user => current_user.email)
            redirect_to '/hoegi105/error'
        else
            @useremail = current_user.email
            agreement = Proscon.new
            agreement.review_id = params[:id]
            agreement.agree_user = @useremail
            agreement.save
            likecount = Review.find(params[:id])
            likecount._like = Proscon.where(:review_id => params[:id], :disagree_user => nil).count
            likecount.save
            
            redirect_to :back
        end
    end
    
    def like_cancel
        if user_signed_in?
	        useremail = current_user.email
	    else
	        redirect_to ''
        end
            @useremail = current_user.email
            agreement = Proscon.find_by(:review_id => params[:id], :agree_user => @useremail)
            agreement.destroy
            likecount = Review.find(params[:id])
            likecount._like = Proscon.where(:review_id => params[:id], :disagree_user => nil).count
            likecount.save
            
            redirect_to :back
    end
        
    
    def dislike
        if user_signed_in?
	        useremail = current_user.email
	    else
	        redirect_to ''
        end
        
        if Proscon.exists?(:review_id => params[:id], :disagree_user => current_user.email)
            redirect_to '/hoegi105/error'
        elsif Proscon.exists?(:review_id => params[:id], :agree_user => current_user.email)
            redirect_to '/hoegi105/error'
        else
            @useremail = current_user.email
            disagreement = Proscon.new
            disagreement.review_id = params[:id] 
            disagreement.disagree_user = @useremail
            disagreement.save
            likecount = Review.find(params[:id])
            likecount._dislike = Proscon.where(:review_id => params[:id], :agree_user => nil).count
            likecount.save
            
            redirect_to :back
        end
    end
    
    def dislike_cancel
        if user_signed_in?
	        useremail = current_user.email
	    else
	        redirect_to ''
        end
            @useremail = current_user.email
            disagreement = Proscon.find_by(:review_id => params[:id], :disagree_user => @useremail)
            disagreement.destroy
            likecount = Review.find(params[:id])
            likecount._dislike = Proscon.where(:review_id => params[:id], :agree_user => nil).count
            likecount.save
            
            redirect_to :back
    end
    
    def error
    end
end
