library(dplyr)
library(ROI)
library(ROI.plugin.glpk)
library(ompr)
library(ompr.roi)

MIPModel() %>%
    add_variable(f[i], i=1:7, type='integer') %>% #set the variables for full-time nurses starting a cycle
    add_variable(p[i], i=1:7, type='integer') %>% #set the variables for part-time nurses starting a cycle
    set_objective( 
        ((f[1]+f[4]+f[5]+f[6]+f[7])*250+(p[1]+p[6]+p[7])*150)+ #monday 1
        ((f[1]+f[2]+f[5]+f[6]+f[7])*250+(p[1]+p[2]+p[7])*150)+ #tuesday 2
        ((f[1]+f[2]+f[3]+f[6]+f[7])*250+(p[1]+p[2]+p[3])*150)+ #wednesday 3
        ((f[1]+f[2]+f[3]+f[4]+f[7])*250+(p[2]+p[3]+p[4])*150)+ #thursday 4
        ((f[1]+f[2]+f[3]+f[4]+f[5])*250+(p[3]+p[4]+p[5])*150)+ #friday 5
        ((f[2]+f[3]+f[4]+f[5]+f[6])*315+(p[4]+p[5]+p[6])*185)+ #saturday 6
        ((f[3]+f[4]+f[5]+f[6]+f[7])*375+(p[5]+p[6]+p[7])*225) #sunday 7
        ,'min') %>% #setting objective function to minimize the weekly cost
    add_constraint( (f[1]+f[4]+f[5]+f[6]+f[7])+(p[1]+p[6]+p[7]) >= 17 ) %>% #monday min 1
    add_constraint( (f[1]+f[2]+f[5]+f[6]+f[7])+(p[1]+p[2]+p[7]) >= 13 ) %>% #tuesday min 2
    add_constraint( (f[1]+f[2]+f[3]+f[6]+f[7])+(p[1]+p[2]+p[3]) >= 15 ) %>% #wednesday min 3
    add_constraint( (f[1]+f[2]+f[3]+f[4]+f[7])+(p[2]+p[3]+p[4]) >= 19 ) %>% #thursday min 4
    add_constraint( (f[1]+f[2]+f[3]+f[4]+f[5])+(p[3]+p[4]+p[5]) >= 14 ) %>% #friday min 5 
    add_constraint( (f[2]+f[3]+f[4]+f[5]+f[6])+(p[4]+p[5]+p[6]) >= 16 ) %>% #saturday min 6
    add_constraint( (f[3]+f[4]+f[5]+f[6]+f[7])+(p[5]+p[6]+p[7]) >= 11 ) %>% #sunday min 7
    add_constraint(1.25*f[1]+1.25*f[2]+1.25*f[3]+
                   1.25*f[4]+1.25*f[5]+1.25*f[6]+1.25*f[7]+
                   (-2.25)*p[1]+(-2.25)*p[2]+(-2.25)*p[3]+
                   (-2.25)*p[4]+(-2.25)*p[5]+(-2.25)*p[6]+
                   (-2.25)*p[7] >= 0
                   ) %>% #part-time constraint
    set_bounds(f[i], lb=0, i=1:7) %>% #set non-negative
    set_bounds(p[i], lb=0, i=1:7) %>% #set non-negative
    solve_model(with_ROI(solver='glpk', 
                         verbose=TRUE)) -> result

solution <- result$solution
cat("Objective value:", result$objective, "\n")
cat("Optimal solution:", "\n")
print(solution)

library(lpSolve)

objective.in <- c(1250, 1315, 1440, 1440, 1440, 1440, 1375,
                  450, 450, 450, 485, 560, 560, 525)

const.mat <- matrix(
                    c(1,0,0,1,1,1,1,1,0,0,0,0,1,1, #Mon
                      1,1,0,0,1,1,1,1,1,0,0,0,0,1, #Tue
                      1,1,1,0,0,1,1,1,1,1,0,0,0,0, #Wed
                      1,1,1,1,0,0,1,0,1,1,1,0,0,0, #Thu
                      1,1,1,1,1,0,0,0,0,1,1,1,0,0, #Fri
                      0,1,1,1,1,1,0,0,0,0,1,1,1,0, #Sat
                      0,0,1,1,1,1,1,0,0,0,0,1,1,1, #Sun
                      1.25,1.25,1.25,1.25,1.25,1.25,1.25,
                      -2.25,-2.25,-2.25,-2.25,-2.25,-2.25,-2.25,
                      1,0,0,0,0,0,0,0,0,0,0,0,0,0), #part-time constr
                    nrow=9, byrow=TRUE
                    )

const.dir <- c('>=',
               '>=',
               '>=',
               '>=',
               '>=',
               '>=',
               '>=',
               '>=',
               '=='
              )

const.rhs <- c(17,
               13,
               15,
               19,
               14,
               16,
               11,
               0,
               8
              )

lp(direction="min",objective.in,const.mat,const.dir,
      const.rhs,all.int=TRUE)

lp(direction="min",objective.in,const.mat,const.dir,
      const.rhs,all.int=TRUE)$solution

# (
#  (p[1]+p[6]+p[7])+
#  (p[1]+p[2]+p[7])+
#  (p[1]+p[2]+p[3])+
#  (p[2]+p[3]+p[4])+
#  (p[3]+p[4]+p[5])+
#  (p[4]+p[5]+p[6])+
#  (p[5]+p[6]+p[7])
#  ) /
#  ( 
#     (
#      (p[1]+p[6]+p[7])+
#      (p[1]+p[2]+p[7])+
#      (p[1]+p[2]+p[3])+
#      (p[2]+p[3]+p[4])+
#      (p[3]+p[4]+p[5])+
#      (p[4]+p[5]+p[6])+
#      (p[5]+p[6]+p[7])
#     ) +
#     (
#      (f[1]+f[4]+f[5]+f[6]+f[7])+
#      (f[1]+f[2]+f[5]+f[6]+f[7])+
#      (f[1]+f[2]+f[3]+f[6]+f[7])+
#      (f[1]+f[2]+f[3]+f[4]+f[7])+
#      (f[1]+f[2]+f[3]+f[4]+f[5])+
#      (f[2]+f[3]+f[4]+f[5]+f[6])+
#      (f[3]+f[4]+f[5]+f[6]+f[7])
#     )
#  ) <= 0.25#

# #-----------------------#

# (
#  (p[1]+p[6]+p[7])+
#  (p[1]+p[2]+p[7])+
#  (p[1]+p[2]+p[3])+
#  (p[2]+p[3]+p[4])+
#  (p[3]+p[4]+p[5])+
#  (p[4]+p[5]+p[6])+
#  (p[5]+p[6]+p[7])
#  ) <=
#  ( 
#     (
#      (p[1]+p[6]+p[7])+
#      (p[1]+p[2]+p[7])+
#      (p[1]+p[2]+p[3])+
#      (p[2]+p[3]+p[4])+
#      (p[3]+p[4]+p[5])+
#      (p[4]+p[5]+p[6])+
#      (p[5]+p[6]+p[7])
#     ) +
#     (
#      (f[1]+f[4]+f[5]+f[6]+f[7])+
#      (f[1]+f[2]+f[5]+f[6]+f[7])+
#      (f[1]+f[2]+f[3]+f[6]+f[7])+
#      (f[1]+f[2]+f[3]+f[4]+f[7])+
#      (f[1]+f[2]+f[3]+f[4]+f[5])+
#      (f[2]+f[3]+f[4]+f[5]+f[6])+
#      (f[3]+f[4]+f[5]+f[6]+f[7])
#     )
#  ) * 0.25

# #-----------------------#

# 0.25*(f[1]+f[4]+f[5]+f[6]+f[7])+0.25*(f[1]+f[2]+f[5]+f[6]+f[7])+
# 0.25*(f[1]+f[2]+f[3]+f[6]+f[7])+0.25*(f[1]+f[2]+f[3]+f[4]+f[7])+
# 0.25*(f[1]+f[2]+f[3]+f[4]+f[5])+0.25*(f[2]+f[3]+f[4]+f[5]+f[6])+
# 0.25*(f[3]+f[4]+f[5]+f[6]+f[7])-
# 0.75*(p[1]+p[6]+p[7])-0.75*(p[1]+p[2]+p[7])-
# 0.75*(p[1]+p[2]+p[3])-0.75*(p[2]+p[3]+p[4])-
# 0.75*(p[3]+p[4]+p[5])-0.75*(p[4]+p[5]+p[6])-
# 0.75*(p[5]+p[6]+p[7]) >= 0

# #-----------------------#

# 0.25*f[1]+0.25*f[4]+0.25*f[5]+0.25*f[6]+0.25*f[7]+
# 0.25*f[1]+0.25*f[2]+0.25*f[5]+0.25*f[6]+0.25*f[7]+
# 0.25*f[1]+0.25*f[2]+0.25*f[3]+0.25*f[6]+0.25*f[7]+
# 0.25*f[1]+0.25*f[2]+0.25*f[3]+0.25*f[4]+0.25*f[7]+
# 0.25*f[1]+0.25*f[2]+0.25*f[3]+0.25*f[4]+0.25*f[5]+
# 0.25*f[2]+0.25*f[3]+0.25*f[4]+0.25*f[5]+0.25*f[6]+
# 0.25*f[3]+0.25*f[4]+0.25*f[5]+0.25*f[6]+0.25*f[7]-
# 0.75*p[1]-0.75*p[6]-0.75*p[7]-
# 0.75*p[1]-0.75*p[2]-0.75*p[7]-
# 0.75*p[1]-0.75*p[2]-0.75*p[3]-
# 0.75*p[2]-0.75*p[3]-0.75*p[4]-
# 0.75*p[3]-0.75*p[4]-0.75*p[5]-
# 0.75*p[4]-0.75*p[5]-0.75*p[6]-
# 0.75*p[5]-0.75*p[6]-0.75*p[7] >= 0

# #-----------------------#

# 1.25*f[1]+1.25*f[2]+1.25*f[3]+
# 1.25*f[4]+1.25*f[5]+1.25*f[6]+1.25*f[7]+
# (-2.25)*p[1]+(-2.25)*p[2]+(-2.25)*p[3]+
# (-2.25)*p[4]+(-2.25)*p[5]+(-2.25)*p[6]+
# (-2.25)*p[7] >= 0

# ((f[1]+f[4]+f[5]+f[6]+f[7])*250+(p[1]+p[6]+p[7])*150)+ #monday 1
# ((f[1]+f[2]+f[5]+f[6]+f[7])*250+(p[1]+p[2]+p[7])*150)+ #tuesday 2
# ((f[1]+f[2]+f[3]+f[6]+f[7])*250+(p[1]+p[2]+p[3])*150)+ #wednesday 3
# ((f[1]+f[2]+f[3]+f[4]+f[7])*250+(p[2]+p[3]+p[4])*150)+ #thursday 4
# ((f[1]+f[2]+f[3]+f[4]+f[5])*250+(p[3]+p[4]+p[5])*150)+ #friday 5
# ((f[2]+f[3]+f[4]+f[5]+f[6])*315+(p[4]+p[5]+p[6])*185)+ #saturday 6
# ((f[3]+f[4]+f[5]+f[6]+f[7])*375+(p[5]+p[6]+p[7])*225) 

# func = function(x) {
#     (250*f1+250*f4+250*f5+250*f6+250*f7+150*p1+150*p6+150*p7+
#     250*f1+250*f2+250*f5+250*f6+250*f7+150*p1+150*p2+150*p7+
#     250*f1+250*f2+250*f3+250*f6+250*f7+150*p1+150*p2+150*p3+
#     250*f1+250*f2+250*f3+250*f4+250*f7+150*p2+150*p3+150*p4+
#     250*f1+250*f2+250*f3+250*f4+250*f5+150*p3+150*p4+150*p5+
#     315*f2+315*f3+315*f4+315*f5+315*f6+185*p4+185*p5+185*p6+ 
#     375*f3+375*f4+375*f5+375*f6+375*f7+225*p5+225*p6+225*p7)
# }

# library('Deriv')
# Simplify(func, env = parent.frame(), scache = new.env())
